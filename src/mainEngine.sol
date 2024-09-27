// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CustomToken} from "./customToken.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// solc-ignore-next-line invalid-import
import {ISwapRouter02} from "@uniswap/v3-swap-routers/contracts/interfaces/ISwapRouter02.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IWETH9} from "../test/mocks/IWETH.sol";
import {IV3SwapRouter} from "lib/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";

import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IStargate} from "lib/stargate-v2/packages/stg-evm-v2/src/interfaces/IStargate.sol";
import {MainEngineLibrary} from "./mainEngineLibrary.sol";

contract MainEngine is IERC721Receiver, Ownable, ILayerZeroComposer {
    uint256 public constant LIQUIDITY_LOCK_PERIOD = 3 days;
    uint24 public constant poolFee = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;
    uint256 public immutable MIN_AMOUNT = 1e15;

    using OptionsBuilder for bytes;

    struct TokenInfo {
        address creator;
        bool initialLiquidityAdded;
        uint256 positionId;
        uint256 lockedLiquidityPercentage;
        uint256 withdrawableLiquidity;
        uint256 creationTime;
        address pool;
        uint128 liquidity;
    }

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    mapping(address => TokenInfo) public tokenInfo;
    mapping(uint256 => Deposit) public deposits;

    IUniswapV3Factory public immutable factory;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    ISwapRouter02 public immutable swapRouter02;
    address public immutable WETH9;
    address public immutable stargatePoolNative;
    address public immutable endpointV2;

    event AdditionalTokenData(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        string description,
        string imageUrl,
        string twitter,
        string telegram,
        string website,
        uint256 timestamp
    );

    event TokenUpdate(
        address indexed tokenAddress,
        address indexed creator,
        uint160 sqrtPriceX96,
        uint256 tokenPrice,
        uint128 liquidity,
        uint256 ethReserve,
        uint256 tokenReserve,
        uint256 totalSupply,
        uint256 lockedLiquidityPercentage,
        uint256 withdrawableLiquidity,
        uint256 liquidatedLiquidity,
        uint256 timestamp
    );

    enum TradeType {
        Buy,
        Sell,
        FailedCrossChainBuy
    }
    enum FailType {
        CrossChainBuy
    }

    event TokenTrade(
        address indexed tokenAddress,
        address indexed trader,
        TradeType tradeType,
        uint256 inputAmount,
        uint256 outputAmount,
        uint32 eid,
        uint256 timestamp
    );

    error InsufficientFunds();
    error Unauthorized();
    error InvalidInput();
    error InvalidOperation();
    error TimingConstraint();
    error CalculationError();
    error TransferFailed();
    error InvalidParameters();
    error LiquidityError();
    error InsufficientFundsForCrossMessage();
    error WETH9Failed();
    constructor(
        IUniswapV3Factory _factory,
        INonfungiblePositionManager _nonfungiblePositionManager,
        ISwapRouter02 _swapRouter02,
        address _WETH9,
        address _stargatePoolNative,
        address _endpointV2
    ) Ownable(msg.sender) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter02 = _swapRouter02;
        WETH9 = _WETH9;
        stargatePoolNative = _stargatePoolNative;
        endpointV2 = _endpointV2;
    }

    modifier onlyTokenCreator(address tokenAddress) {
        if (msg.sender != tokenInfo[tokenAddress].creator) revert Unauthorized();
        _;
    }

    function createTokenAndAddLiquidity(
        address tokenCreator,
        string memory name,
        string memory symbol,
        string memory description,
        string memory imageUrl,
        string memory twitter,
        string memory telegram,
        string memory website,
        uint256 initialSupply,
        uint256 lockedLiquidityPercentage
    ) public payable returns (address tokenAddress) {
        return _createTokenAndAddLiquidity(
            tokenCreator,
            name,
            symbol,
            description,
            imageUrl,
            twitter,
            telegram,
            website,
            initialSupply,
            lockedLiquidityPercentage,
            msg.value
        );
    }

    function _createTokenAndAddLiquidity(
        address tokenCreator,
        string memory name,
        string memory symbol,
        string memory description,
        string memory imageUrl,
        string memory twitter,
        string memory telegram,
        string memory website,
        uint256 initialSupply,
        uint256 lockedLiquidityPercentage,
        uint256 ethAmount
    ) internal returns (address tokenAddress) {
        //TODO CHANGE TO 0.005
        if (ethAmount < MIN_AMOUNT) {
            revert InsufficientFunds();
        }
        //TODO ADD UP TO RATIO IF STATEMNT
        // Wrap the ETH to WETH9
        _wrapETH(ethAmount);

        if (initialSupply == 0 || lockedLiquidityPercentage > 100) {
            revert InvalidInput();
        }
        tokenAddress = _createToken(name, symbol, description, imageUrl, twitter, telegram, website, initialSupply);

        tokenInfo[tokenAddress] = TokenInfo({
            creator: tokenCreator,
            initialLiquidityAdded: false,
            positionId: 0,
            lockedLiquidityPercentage: lockedLiquidityPercentage,
            withdrawableLiquidity: 0,
            creationTime: block.timestamp,
            pool: address(0),
            liquidity: 0
        });

        _setupPool(tokenAddress, ethAmount);

        (uint160 sqrtPriceX96, int24 tick) = MainEngineLibrary.getPoolSlot0(tokenInfo[tokenAddress].pool);
        uint256 currentPrice = MainEngineLibrary.calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);

        (int24 lower, int24 upper) = MainEngineLibrary.calculateTickRange(tick, currentPrice);

        _addInitialLiquidity(tokenAddress, initialSupply, ethAmount, lower, upper);

        emit AdditionalTokenData(
            tokenAddress, tokenCreator, name, symbol, description, imageUrl, twitter, telegram, website, block.timestamp
        );
        _emitTokenUpdate(tokenAddress);
        return tokenAddress;
    }

    function _lzComposeCreateTokenAndAddLiquidity(
        address tokenCreator,
        string memory name,
        string memory symbol,
        string memory description,
        string memory imageUrl,
        string memory twitter,
        string memory telegram,
        string memory website,
        uint256 initialSupply,
        uint256 lockedLiquidityPercentage,
        uint256 ethAmount
    ) internal returns (address tokenAddress) {
        if (ethAmount < MIN_AMOUNT) {
            revert InsufficientFunds();
        }
        // Wrap the ETH to WETH9
        _wrapETH(ethAmount);

        if (initialSupply == 0 || lockedLiquidityPercentage > 100) {
            revert InvalidInput();
        }
        tokenAddress = _createToken(name, symbol, description, imageUrl, twitter, telegram, website, initialSupply);

        tokenInfo[tokenAddress] = TokenInfo({
            creator: tokenCreator,
            initialLiquidityAdded: false,
            positionId: 0,
            lockedLiquidityPercentage: lockedLiquidityPercentage,
            withdrawableLiquidity: 0,
            creationTime: block.timestamp,
            pool: address(0),
            liquidity: 0
        });

        _setupPool(tokenAddress, ethAmount);

        (uint160 sqrtPriceX96, int24 tick) = MainEngineLibrary.getPoolSlot0(tokenInfo[tokenAddress].pool);
        uint256 currentPrice = MainEngineLibrary.calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);

        (int24 lower, int24 upper) = MainEngineLibrary.calculateTickRange(tick, currentPrice);

        _addInitialLiquidity(tokenAddress, initialSupply, ethAmount, lower, upper);

        emit AdditionalTokenData(
            tokenAddress, tokenCreator, name, symbol, description, imageUrl, twitter, telegram, website, block.timestamp
        );
        _emitTokenUpdate(tokenAddress);
        return tokenAddress;
    }

    function _createToken(
        string memory name,
        string memory symbol,
        string memory description,
        string memory imageUrl,
        string memory twitter,
        string memory telegram,
        string memory website,
        uint256 initialSupply
    ) internal returns (address tokenAddress) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        tokenAddress = Create2.deploy(
            0,
            salt,
            abi.encodePacked(
                type(CustomToken).creationCode,
                abi.encode(
                    name, symbol, description, imageUrl, twitter, telegram, website, address(this), initialSupply
                )
            )
        );

        return tokenAddress;
    }

    function _setupPool(address tokenAddress, uint256 ethAmount) internal {
        if (tokenInfo[tokenAddress].pool != address(0)) {
            revert();
        }

        // Order tokens
        (address token0, address token1) = MainEngineLibrary.orderTokens(tokenAddress, WETH9);

        // Create pool
        address pool = factory.createPool(token0, token1, poolFee);
        tokenInfo[tokenAddress].pool = pool;

        // Get token balances
        uint256 tokenAmount = IERC20Metadata(tokenAddress).balanceOf(address(this));

        // Calculate the initial sqrtPriceX96
        uint160 sqrtPriceX96 = MainEngineLibrary.calculateInitialSqrtPrice(
            token0,
            token1,
            token0 == tokenAddress ? tokenAmount : ethAmount,
            token1 == tokenAddress ? tokenAmount : ethAmount
        );

        // Initialize the pool with the calculated price
        IUniswapV3Pool(pool).initialize(sqrtPriceX96);
    }

    function _addInitialLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        if (tokenInfo[tokenAddress].initialLiquidityAdded) {
            revert InvalidOperation();
        }
        if (tokenAmount == 0 || ethAmount == 0) {
            revert InvalidInput();
        }

        (address token0, address token1) = MainEngineLibrary.orderTokens(tokenAddress, WETH9);
        uint256 amount0 = (token0 == tokenAddress) ? tokenAmount : ethAmount;
        uint256 amount1 = (token1 == tokenAddress) ? tokenAmount : ethAmount;
        TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), amount0);
        TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), amount1);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: poolFee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        (uint256 tokenId, uint128 liquidity,,) = nonfungiblePositionManager.mint(params);

        if (liquidity <= 0) {
            revert LiquidityError();
        }

        tokenInfo[tokenAddress].positionId = tokenId;
        tokenInfo[tokenAddress].liquidity = liquidity;
        tokenInfo[tokenAddress].initialLiquidityAdded = true;
        tokenInfo[tokenAddress].withdrawableLiquidity =
            liquidity * (100 - tokenInfo[tokenAddress].lockedLiquidityPercentage) / 100;

        deposits[tokenId] = Deposit({owner: msg.sender, liquidity: liquidity, token0: token0, token1: token1});
    }

    function lzCompose(
        address _from,
        bytes32, /*_guid*/
        bytes calldata _message,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) external payable {
        if (_from != stargatePoolNative || msg.sender != endpointV2) {
            revert Unauthorized();
        }
        uint256 amountLD = OFTComposeMsgCodec.amountLD(_message);
        uint32 srcEid = OFTComposeMsgCodec.srcEid(_message);
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

        (bytes1 transactionType, bytes memory data) = abi.decode(_composeMessage, (bytes1, bytes));

        if (transactionType == 0x00) {
            (
                address tokenCreator,
                string memory name,
                string memory symbol,
                string memory description,
                string memory imageUrl,
                string memory twitter,
                string memory telegram,
                string memory website,
                uint256 initialSupply,
                uint256 lockedLiquidityPercentage
            ) = abi.decode(data, (address, string, string, string, string, string, string, string, uint256, uint256));

            address tokenAddress = _lzComposeCreateTokenAndAddLiquidity(
                tokenCreator,
                name,
                symbol,
                description,
                imageUrl,
                twitter,
                telegram,
                website,
                initialSupply,
                lockedLiquidityPercentage,
                amountLD
            );
        } else if (transactionType == 0x01) {
            (address tokenAddress, address recipient) = abi.decode(data, (address, address));
            _lzComposeSwapExactETHForTokens(tokenAddress, amountLD, recipient, srcEid);
        } else if (transactionType == 0x02) {
            (address tokenAddress, uint256 tokenAmount, address recipient) =
                abi.decode(data, (address, uint256, address));

            // Emit TokenTrade event
            emit TokenTrade(tokenAddress, recipient, TradeType.Buy, amountLD, tokenAmount, srcEid, block.timestamp);

            // Update token-related data
            _emitTokenUpdate(tokenAddress);
        } else {
            revert InvalidInput();
        }
    }

    function _lzComposeSwapExactETHForTokens(address _tokenAddress, uint256 _amount, address _recipient, uint32 _srcEid)
        internal
        returns (uint256 amountOut)
    {
        if (_amount == 0) revert InsufficientFunds();

        // Wrap the ETH to WETH9
        _wrapETH(_amount);

        // Approve the swap router to spend WETH9
        TransferHelper.safeApprove(WETH9, address(swapRouter02), _amount);

        // Set up swap parameters
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: _tokenAddress,
            fee: poolFee,
            recipient: _recipient,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Attempt the swap with try-catch
        try swapRouter02.exactInputSingle(params) returns (uint256 out) {
            amountOut = out;
            emit TokenTrade(_tokenAddress, _recipient, TradeType.Buy, _amount, amountOut, _srcEid, block.timestamp);

            // Update token-related data
            _emitTokenUpdate(_tokenAddress);
        } catch {
            // If the swap fails, unwrap WETH back to ETH
            _unwrapETH(_amount);

            // Use Stargate to send ETH back to the user on the source chain
            bytes32 to = OFTComposeMsgCodec.addressToBytes32(_recipient);

            SendParam memory sendParam = SendParam({
                dstEid: _srcEid,
                to: to,
                amountLD: _amount,
                minAmountLD: 0, // 0.5% slippage tolerance
                extraOptions: "",
                composeMsg: "", // No compose message
                oftCmd: ""
            });

            MessagingFee memory messagingFee = IStargate(stargatePoolNative).quoteSend(sendParam, false);

            if (_amount <= messagingFee.nativeFee) {
                (bool success,) = _recipient.call{value: _amount}("");
                if (!success) {
                    revert TransferFailed();
                }
                emit TokenTrade(
                    _tokenAddress, _recipient, TradeType.FailedCrossChainBuy, _amount, 0, 0, block.timestamp
                );
            }

            uint256 amountToSend = _amount - messagingFee.nativeFee;
            sendParam.amountLD = amountToSend;

            IStargate(stargatePoolNative).sendToken{value: _amount}(sendParam, messagingFee, _recipient);

            emit TokenTrade(
                _tokenAddress, _recipient, TradeType.FailedCrossChainBuy, _amount, 0, _srcEid, block.timestamp
            );
        }

        // Emit trade event upon successful swap

        return amountOut;
    }



    function _wrapETH(uint256 amount) internal {
        try IWETH9(WETH9).deposit{value: amount}() {}
        catch {
            revert WETH9Failed();
        }
    }

    function _unwrapETH(uint256 amount) internal {
        try IWETH9(WETH9).withdraw(amount) {}
        catch {
            revert WETH9Failed();
        }
    }

    function withdrawLiquidity(address tokenAddress, uint256 amount) external onlyTokenCreator(tokenAddress) {
        if (block.timestamp < tokenInfo[tokenAddress].creationTime + LIQUIDITY_LOCK_PERIOD) revert TimingConstraint();
        if (amount > tokenInfo[tokenAddress].withdrawableLiquidity) revert InsufficientFunds();

        tokenInfo[tokenAddress].withdrawableLiquidity -= amount;

        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: tokenInfo[tokenAddress].positionId,
            liquidity: uint128(amount),
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

        INonfungiblePositionManager.CollectParams memory collectParams = INonfungiblePositionManager.CollectParams({
            tokenId: tokenInfo[tokenAddress].positionId,
            recipient: msg.sender,
            amount0Max: uint128(amount0),
            amount1Max: uint128(amount1)
        });

        nonfungiblePositionManager.collect(collectParams);
    }

    function swapExactTokensForETH(address tokenAddress, uint256 tokenAmount, uint32 dstEid)
        external
        returns (uint256)
    {
        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenAmount);
        TransferHelper.safeApprove(tokenAddress, address(swapRouter02), tokenAmount);

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: tokenAddress,
            tokenOut: WETH9,
            fee: poolFee,
            recipient: address(this),
            amountIn: tokenAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = swapRouter02.exactInputSingle(params);

        IWETH9(WETH9).withdraw(amountOut);

        if (dstEid != 0) {
            _sendViaStargate(dstEid, amountOut, msg.sender, tokenAddress, tokenAmount);
        } else {
            // Transfer ETH directly to the user on the current chain
            (bool success,) = msg.sender.call{value: amountOut}("");
            if (!success) {
                revert TransferFailed();
            }
            // Get price after trade

            emit TokenTrade(tokenAddress, msg.sender, TradeType.Sell, tokenAmount, amountOut, 0, block.timestamp);
            _emitTokenUpdate(tokenAddress);
        }

        return amountOut;
    }

    function _sendViaStargate(
        uint32 dstEid,
        uint256 amount,
        address recipient,
        address tokenAddress,
        uint256 tokenAmount
    ) internal {
        if (dstEid == 0) {
            revert InvalidParameters();
        }
        if (amount == 0) {
            revert InvalidInput();
        }

        bytes32 to = OFTComposeMsgCodec.addressToBytes32(recipient);

        bytes memory composeMsg = abi.encode(bytes1(0x02), abi.encode(tokenAddress, tokenAmount, recipient));

        bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzComposeOption(0, 200_000, 0);

        SendParam memory sendParam = SendParam({
            dstEid: dstEid,
            to: to,
            amountLD: amount,
            minAmountLD: amount * 300 / 1000, // Example: 0.5% slippage tolerance
            extraOptions: extraOptions,
            composeMsg: composeMsg,
            oftCmd: ""
        });

        MessagingFee memory messagingFee = IStargate(stargatePoolNative).quoteSend(sendParam, false);

        // Combined check for insufficient ETH and minimum send amount
        if (amount <= messagingFee.nativeFee) {
            revert InsufficientFundsForCrossMessage();
        }
        if (amount - messagingFee.nativeFee < MIN_AMOUNT) {
            revert InsufficientFundsForCrossMessage();
        }
        sendParam.amountLD = amount - messagingFee.nativeFee;

        IStargate(stargatePoolNative).sendToken{value: amount}(sendParam, messagingFee, recipient);
    }

    function swapExactETHForTokens(address tokenAddress) external payable returns (uint256) {
        if (msg.value == 0) revert InsufficientFunds();
        // Get price before trade
        _wrapETH(msg.value);

        TransferHelper.safeApprove(WETH9, address(swapRouter02), msg.value);

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: tokenAddress,
            fee: poolFee,
            recipient: msg.sender,
            amountIn: msg.value,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = swapRouter02.exactInputSingle(params);
        // Get price after trade
        emit TokenTrade(tokenAddress, msg.sender, TradeType.Buy, msg.value, amountOut, 0, block.timestamp);
        _emitTokenUpdate(tokenAddress);

        return amountOut;
    }

    function _emitTokenUpdate(address tokenAddress) internal {
        address pool = tokenInfo[tokenAddress].pool;
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

        uint128 liquidity = IUniswapV3Pool(pool).liquidity();

        (uint256 tokenReserve, uint256 ethReserve) =
            MainEngineLibrary.getPoolReserves(tokenAddress, WETH9, tokenInfo[tokenAddress].pool);

        uint256 totalSupply = IERC20Metadata(tokenAddress).totalSupply();
        uint256 liquidatedLiquidity = tokenInfo[tokenAddress].liquidity - tokenInfo[tokenAddress].withdrawableLiquidity;
        address creator = tokenInfo[tokenAddress].creator;
        uint256 tokenPrice = MainEngineLibrary.calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);
        emit TokenUpdate(
            tokenAddress,
            creator,
            sqrtPriceX96,
            tokenPrice,
            liquidity,
            ethReserve,
            tokenReserve,
            totalSupply,
            tokenInfo[tokenAddress].lockedLiquidityPercentage,
            tokenInfo[tokenAddress].withdrawableLiquidity,
            liquidatedLiquidity,
            block.timestamp
        );
    }

    function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /* tokenId*/ bytes calldata)
        external
        view
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
