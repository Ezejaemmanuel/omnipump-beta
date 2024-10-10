// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CustomToken} from "./customToken.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {ISwapRouter02} from "@uniswap/v3-swap-routers/contracts/interfaces/ISwapRouter02.sol";
import {IWETH9} from "../test/mocks/IWETH.sol";
import {IV3SwapRouter} from "lib/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
import {
    MessagingParams,
    MessagingFee,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {IStargate} from "lib/stargate-v2/packages/stg-evm-v2/src/interfaces/IStargate.sol";
import {KannonV1Library} from "./kannon_v1_library.sol";
import {OAppReceiver} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import {OAppCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OApp} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

contract KannonV1 is Ownable, OApp {
    uint256 public constant LIQUIDITY_LOCK_PERIOD = 3 days;
    uint24 public constant poolFee = 3000; // 0.3%
    uint256 constant PRECISION_13 = 1e13;
    uint64 public version;

    uint256 public immutable MIN_AMOUNT = 1e15;

    using OptionsBuilder for bytes;

    struct TokenCreationParams {
        string name;
        string symbol;
        string description;
        string imageUrl;
        string twitter;
        string telegram;
        string website;
        uint256 initialSupply;
        uint256 ethTarget;
        uint256 presaleDuration;
        address tokenCreator;
    }

    mapping(address => TokenCreationParams) private tokenCreationParams;

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

    struct Origin {
        uint32 srcEid; // The source chain's Endpoint ID.
        bytes32 sender; // The sending OApp address.
        uint64 nonce; // The message nonce for the pathway.
    }

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    KannonV1Library.PresaleRatios public presaleRatios;
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
        uint256 ethReserve,
        uint256 tokenReserve,
        uint256 totalSupply,
        uint256 lockedLiquidityPercentage,
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

    error KannonV1_InvalidRatios();
    error KannonV1_Unauthorized();
    error KannonV1_PresaleAlreadyStarted();
    error KannonV1_InvalidParameters();

    constructor(
        IUniswapV3Factory _factory,
        INonfungiblePositionManager _nonfungiblePositionManager,
        ISwapRouter02 _swapRouter02,
        address _WETH9,
        address _stargatePoolNative,
        address _endpointV2,
        uint64 _version,
        uint256 _phase1Ratio,
        uint256 _phase2Ratio,
        uint256 _launchRatio
    ) OApp(_endpointV2, msg.sender) Ownable(msg.sender) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter02 = _swapRouter02;
        WETH9 = _WETH9;
        stargatePoolNative = _stargatePoolNative;
        endpointV2 = _endpointV2;
        version = _version;
        // Validate and set the presale ratios
        if (_phase1Ratio + _phase2Ratio + _launchRatio != 1000) {
            revert KannonV1_InvalidRatios();
        }
        presaleRatios = KannonV1Library.PresaleRatios({
            phase1Ratio: _phase1Ratio,
            phase2Ratio: _phase2Ratio,
            launchRatio: _launchRatio
        });
    }

    function quote(uint32 _dstEid, address _receiver, bytes memory payload, bytes memory options, bool _payInLzToken)
        public
        view
        returns (MessagingFee memory fee)
    {
        return _quote(_dstEid, payload, options, _payInLzToken);
    }

    event ReachedSendMessageFunction(string indexed message);

    function sendMessage(
        uint32 _dstEid,
        address _receiver,
        bytes memory options,
        bytes memory payload,
        MessagingFee memory _fee
    ) public payable returns (MessagingReceipt memory receipt) {
        // Verify that the sent value matches the quoted native fee
        if (msg.value < _fee.nativeFee) {
            revert KannonV1Library.KannonV1_InsufficientFundsForCrossMessage();
        }
        emit ReachedSendMessageFunction("reached 1");
        // Send the message
        receipt = _lzSend(_dstEid, payload, options, _fee, payable(msg.sender));
        emit ReachedSendMessageFunction("i have finished running lzSend");
        return receipt;
    }

    // function lzReceive(
    //     Origin calldata _origin,
    //     bytes32 _guid,
    //     bytes calldata _message,
    //     address _executor,
    //     bytes calldata _extraData
    // ) public payable {
    //     // Ensures that only the endpoint can attempt to lzReceive() messages to this OApp.
    //     if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);

    //     // Ensure that the sender matches the expected peer for the source endpoint.
    //     if (_getPeerOrRevert(_origin.srcEid) != _origin.sender) revert OnlyPeer(_origin.srcEid, _origin.sender);

    //     // Call the internal OApp implementation of lzReceive.
    //     _lzReceive(_origin, _guid, _message, _executor, _extraData);
    // }
    /**
     * @dev Internal function to implement lzReceive logic without needing to copy the basic parameter validation.
     */

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal {
        (bytes1 transactionType, bytes memory data) = abi.decode(_message, (bytes1, bytes));

        if (transactionType == 0x03) {
            TokenPresaleParams memory params = abi.decode(data, (TokenPresaleParams));
            address sender = OFTComposeMsgCodec.bytes32ToAddress(_origin.sender);

            params.tokenParams.userAddress = sender;
            _createTokenAndStartPresale(params);
        } else {
            revert KannonV1Library.KannonV1_InvalidInput();
        }
    }

    function updatePresaleRatios(uint256 _phase1Ratio, uint256 _phase2Ratio, uint256 _launchRatio) external onlyOwner {
        if (_phase1Ratio + _phase2Ratio + _launchRatio != 1000) {
            revert KannonV1_InvalidRatios();
        }
        presaleRatios = KannonV1Library.PresaleRatios({
            phase1Ratio: _phase1Ratio,
            phase2Ratio: _phase2Ratio,
            launchRatio: _launchRatio
        });
    }

    event PresaleParticipation(
        address indexed tokenAddress,
        address indexed participant,
        KannonV1Library.LaunchPhase currentPhase,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 refund,
        uint256 timestamp
    );
    event TokenClaimed(address indexed token, address indexed user, uint256 amount, uint256 timestamp);
    event PresaleUpdate(
        address indexed tokenAddress,
        address indexed creator,
        KannonV1Library.LaunchPhase currentPhase,
        uint256 ethCollected,
        uint256 totalPresoldTokens,
        uint256 distributableSupply,
        uint256 ethTarget,
        uint256 launchDeadline,
        uint256 tokenPrice,
        uint256 timestamp
    );
    event PresaleCompleted(address indexed tokenAddress, uint256 timestamp);
    event AdditionalPresaleTokenData(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        string description,
        string imageUrl,
        string twitter,
        string telegram,
        string website,
        uint256 initialSupply,
        uint256 ethTarget,
        uint256 presaleDuration,
        uint256 timestamp
    );

    struct LaunchInfo {
        address creator;
        KannonV1Library.LaunchPhase currentPhase;
        uint256 launchDeadline;
        uint256 distributableSupply;
        uint256 ethTarget;
        uint256 ethCollected;
        uint256 totalPresoldTokens;
        uint256 k;
    }

    mapping(address => LaunchInfo) public tokenLaunchInfo;
    mapping(address => mapping(address => uint256)) public userPresale;

    struct TokenParams {
        address userAddress;
        string name;
        string symbol;
        string description;
        string imageUrl;
        string twitter;
        string telegram;
        string website;
        uint256 initialSupply;
    }

    struct TokenLiquidityParams {
        TokenParams tokenParams;
        uint256 lockedLiquidityPercentage;
        uint256 ethAmount;
    }

    struct TokenPresaleParams {
        TokenParams tokenParams;
        uint256 ethTarget;
        uint256 presaleDuration;
    }

    function createTokenAndStartPresale(TokenPresaleParams memory params) external returns (address tokenAddress) {
        params.tokenParams.userAddress = msg.sender;

        return _createTokenAndStartPresale(params);
    }

    function _createTokenAndStartPresale(TokenPresaleParams memory params) internal returns (address tokenAddress) {
        tokenAddress = _createToken(params.tokenParams);

        // Store the parameters
        tokenCreationParams[tokenAddress] = TokenCreationParams({
            name: params.tokenParams.name,
            symbol: params.tokenParams.symbol,
            description: params.tokenParams.description,
            imageUrl: params.tokenParams.imageUrl,
            twitter: params.tokenParams.twitter,
            telegram: params.tokenParams.telegram,
            website: params.tokenParams.website,
            initialSupply: params.tokenParams.initialSupply,
            ethTarget: params.ethTarget,
            presaleDuration: params.presaleDuration,
            tokenCreator: params.tokenParams.userAddress
        });

        _startInitialPresale(
            tokenAddress,
            params.tokenParams.initialSupply,
            params.ethTarget,
            params.presaleDuration,
            params.tokenParams.userAddress
        );
        emit AdditionalPresaleTokenData(
            tokenAddress,
            params.tokenParams.userAddress,
            params.tokenParams.name,
            params.tokenParams.symbol,
            params.tokenParams.description,
            params.tokenParams.imageUrl,
            params.tokenParams.twitter,
            params.tokenParams.telegram,
            params.tokenParams.website,
            params.tokenParams.initialSupply,
            params.ethTarget,
            params.presaleDuration,
            block.timestamp
        );

        return tokenAddress;
    }

    function _startInitialPresale(
        address tokenAddress,
        uint256 initialSupply,
        uint256 ethTarget,
        uint256 presaleDuration,
        address presaleCreator
    ) internal {
        KannonV1Library.PresaleInfo memory info =
            KannonV1Library.calculatePresaleInfo(initialSupply, ethTarget, presaleRatios);

        tokenLaunchInfo[tokenAddress] = LaunchInfo({
            creator: presaleCreator,
            currentPhase: KannonV1Library.LaunchPhase.InitialPresale,
            launchDeadline: block.timestamp + presaleDuration,
            distributableSupply: info.distributableSupply,
            ethTarget: ethTarget,
            ethCollected: 0,
            totalPresoldTokens: 0,
            k: info.k
        });

        emit PresaleUpdate(
            tokenAddress,
            presaleCreator,
            KannonV1Library.LaunchPhase.InitialPresale,
            0,
            0,
            info.distributableSupply,
            ethTarget,
            block.timestamp + presaleDuration,
            info.initialPrice,
            block.timestamp
        );
    }

    function _addLiquidityAfterPresale(address tokenAddress, address userAddress) internal {
        TokenCreationParams memory params = tokenCreationParams[tokenAddress];

        KannonV1Library.LiquidityAfterPresaleData memory liquidityData = KannonV1Library.getLiquidityAfterPresaleData(
            tokenAddress,
            WETH9,
            tokenLaunchInfo[tokenAddress].ethCollected,
            tokenLaunchInfo[tokenAddress].distributableSupply,
            tokenLaunchInfo[tokenAddress].totalPresoldTokens,
            tokenInfo[tokenAddress].pool
        );

        _wrapETH(liquidityData.ethAmount);

        // Use 100% as locked liquidity percentage for presale tokens
        tokenInfo[tokenAddress] = TokenInfo({
            creator: params.tokenCreator,
            initialLiquidityAdded: false,
            positionId: 0,
            lockedLiquidityPercentage: 100,
            withdrawableLiquidity: 0,
            creationTime: block.timestamp,
            pool: address(0),
            liquidity: 0
        });

        _setupPool(tokenAddress, liquidityData.ethAmount, liquidityData.tokenAmount);
        _addInitialLiquidity(
            tokenAddress,
            liquidityData.tokenAmount,
            liquidityData.ethAmount,
            liquidityData.lower,
            liquidityData.upper,
            userAddress
        );

        tokenInfo[tokenAddress] = TokenInfo({
            creator: params.tokenCreator,
            initialLiquidityAdded: true,
            positionId: tokenInfo[tokenAddress].positionId,
            lockedLiquidityPercentage: 100,
            withdrawableLiquidity: 0,
            creationTime: block.timestamp,
            pool: tokenInfo[tokenAddress].pool,
            liquidity: tokenInfo[tokenAddress].liquidity
        });

        emit AdditionalTokenData(
            tokenAddress,
            params.tokenCreator,
            params.name,
            params.symbol,
            params.description,
            params.imageUrl,
            params.twitter,
            params.telegram,
            params.website,
            block.timestamp
        );
        _emitTokenUpdate(tokenAddress);
    }

    function participateInPresale(address tokenAddress) external payable {
        _participateInPresale(tokenAddress, msg.sender, msg.value);
    }

    function _participateInPresale(address tokenAddress, address userAddress, uint256 msgValue) internal {
        LaunchInfo storage launchInfo = tokenLaunchInfo[tokenAddress];

        if (
            launchInfo.currentPhase != KannonV1Library.LaunchPhase.InitialPresale
                && launchInfo.currentPhase != KannonV1Library.LaunchPhase.IntermediatePresale
        ) {
            revert KannonV1Library.KannonV1_InvalidPhase();
        }

        if (block.timestamp > launchInfo.launchDeadline) {
            if (launchInfo.currentPhase == KannonV1Library.LaunchPhase.FinalLaunch) {
                revert KannonV1Library.KannonV1_DeadlineReached();
            } else {
                _transitionToFinalLaunch(tokenAddress, userAddress);
                (bool success,) = payable(userAddress).call{value: msgValue}("");
                if (!success) {
                    revert KannonV1Library.KannonV1_TransferFailed();
                }
                emit PresaleParticipation(
                    tokenAddress, userAddress, launchInfo.currentPhase, 0, 0, msgValue, block.timestamp
                );
                emit PresaleUpdate(
                    tokenAddress,
                    launchInfo.creator,
                    launchInfo.currentPhase,
                    launchInfo.ethCollected,
                    launchInfo.totalPresoldTokens,
                    launchInfo.distributableSupply,
                    launchInfo.ethTarget,
                    launchInfo.launchDeadline,
                    0,
                    block.timestamp
                );
                return;
            }
        }

        KannonV1Library.PresaleParticipationResult memory result = KannonV1Library.calculatePresaleParticipation(
            launchInfo.currentPhase,
            launchInfo.distributableSupply,
            launchInfo.ethTarget,
            launchInfo.totalPresoldTokens,
            launchInfo.ethCollected,
            launchInfo.k,
            msgValue,
            presaleRatios
        );

        if (result.tokenAmount == 0) {
            revert KannonV1Library.KannonV1_InsufficientFunds();
        }

        launchInfo.ethCollected += result.ethToUse;
        userPresale[tokenAddress][userAddress] += result.tokenAmount;
        launchInfo.totalPresoldTokens += result.tokenAmount;

        _checkAndUpdatePhase(tokenAddress, userAddress);

        if (result.refund > 0) {
            (bool success,) = payable(userAddress).call{value: result.refund}("");
            if (!success) {
                revert KannonV1Library.KannonV1_TransferFailed();
            }
        }

        emit PresaleParticipation(
            tokenAddress,
            userAddress,
            launchInfo.currentPhase,
            result.ethToUse,
            result.tokenAmount,
            result.refund,
            block.timestamp
        );
        emit PresaleUpdate(
            tokenAddress,
            launchInfo.creator,
            launchInfo.currentPhase,
            launchInfo.ethCollected,
            launchInfo.totalPresoldTokens,
            launchInfo.distributableSupply,
            launchInfo.ethTarget,
            launchInfo.launchDeadline,
            result.ethToUse * PRECISION_13 / result.tokenAmount,
            block.timestamp
        );
    }

    function _checkAndUpdatePhase(address tokenAddress, address userAddress) internal {
        // uint256 oneThirdDistributable = tokenLaunchInfo[tokenAddress].distributableSupply / 3;
        // uint256 twoThirdsDistributable = (tokenLaunchInfo[tokenAddress].distributableSupply * 2) / 3;
        uint256 phase1Threshold = (tokenLaunchInfo[tokenAddress].distributableSupply * presaleRatios.phase1Ratio) / 1000;
        uint256 phase2Threshold = (
            tokenLaunchInfo[tokenAddress].distributableSupply * (presaleRatios.phase1Ratio + presaleRatios.phase2Ratio)
        ) / 1000;

        if (block.timestamp > tokenLaunchInfo[tokenAddress].launchDeadline) {
            _transitionToFinalLaunch(tokenAddress, userAddress);
        } else if (
            tokenLaunchInfo[tokenAddress].currentPhase == KannonV1Library.LaunchPhase.InitialPresale
                && tokenLaunchInfo[tokenAddress].totalPresoldTokens >= phase1Threshold
        ) {
            tokenLaunchInfo[tokenAddress].currentPhase = KannonV1Library.LaunchPhase.IntermediatePresale;
        }
        // Check Intermediate Presale condition
        else if (
            tokenLaunchInfo[tokenAddress].currentPhase == KannonV1Library.LaunchPhase.IntermediatePresale
                && tokenLaunchInfo[tokenAddress].totalPresoldTokens >= phase2Threshold
        ) {
            _transitionToFinalLaunch(tokenAddress, userAddress);
        }
    }

    function _transitionToFinalLaunch(address tokenAddress, address userAddress) internal {
        tokenLaunchInfo[tokenAddress].currentPhase = KannonV1Library.LaunchPhase.FinalLaunch;

        _addLiquidityAfterPresale(tokenAddress, userAddress);

        emit PresaleCompleted(tokenAddress, block.timestamp);
    }

    function claimTokens(address tokenAddress) external {
        _claimTokens(tokenAddress, msg.sender);
    }

    function _claimTokens(address tokenAddress, address userAddress) internal {
        if (tokenLaunchInfo[tokenAddress].currentPhase != KannonV1Library.LaunchPhase.FinalLaunch) {
            revert KannonV1Library.KannonV1_PresaleNotComplete();
        }
        uint256 claimAmount = userPresale[tokenAddress][userAddress];
        if (claimAmount == 0) {
            revert KannonV1Library.KannonV1_InsufficientFunds();
        }
        userPresale[tokenAddress][userAddress] = 0;
        IERC20Metadata(tokenAddress).transfer(userAddress, claimAmount);
        emit TokenClaimed(tokenAddress, msg.sender, claimAmount, block.timestamp);
    }

    function getLaunchInfo(address tokenAddress) external view returns (LaunchInfo memory) {
        return tokenLaunchInfo[tokenAddress];
    }

    function getTokenInfo(address tokenAddress) external view returns (TokenInfo memory) {
        return tokenInfo[tokenAddress];
    }

    function createTokenAndAddLiquidity(TokenLiquidityParams memory params)
        external
        payable
        returns (address tokenAddress)
    {
        params.ethAmount = msg.value;
        params.tokenParams.userAddress = msg.sender;
        return _createTokenAndAddLiquidity(params);
    }

    function _createTokenAndAddLiquidity(TokenLiquidityParams memory params) internal returns (address tokenAddress) {
        uint256 ethAmount = params.ethAmount;
        address tokenCreator = params.tokenParams.userAddress;
        uint256 initialSupply = params.tokenParams.initialSupply;
        //TODO CHANGE TO 0.005
        if (ethAmount < MIN_AMOUNT) {
            revert KannonV1Library.KannonV1_InsufficientFunds();
        }
        //TODO ADD UP TO RATIO IF STATEMNT
        // Wrap the ETH to WETH9
        _wrapETH(ethAmount);

        if (initialSupply == 0 || params.lockedLiquidityPercentage > 100) {
            revert KannonV1Library.KannonV1_InvalidInput();
        }
        tokenAddress = _createToken(params.tokenParams);

        tokenInfo[tokenAddress] = TokenInfo({
            creator: params.tokenParams.userAddress,
            initialLiquidityAdded: false,
            positionId: 0,
            lockedLiquidityPercentage: params.lockedLiquidityPercentage,
            withdrawableLiquidity: 0,
            creationTime: block.timestamp,
            pool: address(0),
            liquidity: 0
        });

        _setupPool(tokenAddress, ethAmount, 0);

        (uint160 sqrtPriceX96, int24 tick) = KannonV1Library.getPoolSlot0(tokenInfo[tokenAddress].pool);
        uint256 currentPrice = KannonV1Library.calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress, WETH9);

        (int24 lower, int24 upper) = KannonV1Library.calculateTickRange(tick, currentPrice);

        _addInitialLiquidity(tokenAddress, initialSupply, ethAmount, lower, upper, tokenCreator);

        emit AdditionalTokenData(
            tokenAddress,
            tokenCreator,
            params.tokenParams.name,
            params.tokenParams.symbol,
            params.tokenParams.description,
            params.tokenParams.imageUrl,
            params.tokenParams.twitter,
            params.tokenParams.telegram,
            params.tokenParams.website,
            block.timestamp
        );
        _emitTokenUpdate(tokenAddress);
        return tokenAddress;
    }

    address lastCreatedToken;

    function _createToken(TokenParams memory params) internal returns (address tokenAddress) {
        bytes32 salt = keccak256(abi.encodePacked(params.userAddress, block.timestamp));
        tokenAddress = Create2.deploy(
            0,
            salt,
            abi.encodePacked(
                type(CustomToken).creationCode,
                abi.encode(
                    params.name,
                    params.symbol,
                    params.description,
                    params.imageUrl,
                    params.twitter,
                    params.telegram,
                    params.website,
                    address(this),
                    params.initialSupply
                )
            )
        );
        lastCreatedToken = tokenAddress;
        return tokenAddress;
    }

    function getLastCreatedToken() external view returns (address) {
        return lastCreatedToken;
    }

    function _setupPool(address tokenAddress, uint256 ethAmount, uint256 tokenAmount) internal {
        if (tokenInfo[tokenAddress].pool != address(0)) {
            revert KannonV1Library.KannonV1_PoolNotInitialized();
        }

        // Order tokens
        (address token0, address token1) = KannonV1Library.orderTokens(tokenAddress, WETH9);

        // Create pool
        address pool = factory.createPool(token0, token1, poolFee);
        tokenInfo[tokenAddress].pool = pool;

        // // Get token balances

        uint256 actualTokenAmount;
        if (tokenAmount == 0) {
            actualTokenAmount = IERC20Metadata(tokenAddress).balanceOf(address(this));
        } else {
            actualTokenAmount = tokenAmount;
        }

        // Calculate the initial sqrtPriceX96
        uint160 sqrtPriceX96 = KannonV1Library.calculateInitialSqrtPrice(
            token0,
            token1,
            token0 == tokenAddress ? actualTokenAmount : ethAmount,
            token1 == tokenAddress ? actualTokenAmount : ethAmount
        );

        // Initialize the pool with the calculated price
        IUniswapV3Pool(pool).initialize(sqrtPriceX96);
    }

    function _addInitialLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount,
        int24 tickLower,
        int24 tickUpper,
        address userAddress
    ) internal {
        if (tokenInfo[tokenAddress].initialLiquidityAdded) {
            revert KannonV1Library.KannonV1_InvalidOperation();
        }
        if (tokenAmount == 0 || ethAmount == 0) {
            revert KannonV1Library.KannonV1_InvalidInput();
        }

        (address token0, address token1) = KannonV1Library.orderTokens(tokenAddress, WETH9);
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
            revert KannonV1Library.KannonV1_LiquidityError();
        }

        tokenInfo[tokenAddress].positionId = tokenId;
        tokenInfo[tokenAddress].liquidity = liquidity;
        tokenInfo[tokenAddress].initialLiquidityAdded = true;
        tokenInfo[tokenAddress].withdrawableLiquidity =
            liquidity * (100 - tokenInfo[tokenAddress].lockedLiquidityPercentage) / 100;

        deposits[tokenId] = Deposit({owner: userAddress, liquidity: liquidity, token0: token0, token1: token1});
    }

    // function lzReceive(
    //     Origin calldata _origin,
    //     bytes32, /*_guid*/
    //     bytes calldata _message,
    //     address, /*_executor*/
    //     bytes calldata /*_extraData*/
    // ) external {
    //     if (msg.sender != endpointV2) {
    //         revert KannonV1Library.KannonV1_Unauthorized();
    //     }

    //     // Decode the message
    //     // Decode the message
    //     (bytes1 transactionType, bytes memory data) = abi.decode(_message, (bytes1, bytes));

    //     if (transactionType == 0x03) {
    //         TokenPresaleParams memory params = abi.decode(data, (TokenPresaleParams));
    //         address sender = OFTComposeMsgCodec.bytes32ToAddress(_origin.sender);

    //         params.tokenParams.userAddress = sender;
    //         _createTokenAndStartPresale(params);
    //     } else {
    //         revert KannonV1Library.KannonV1_InvalidInput();
    //     }
    // }

    function lzCompose(
        address _from,
        bytes32, /*_guid*/
        bytes calldata _message,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) external payable {
        if (_from != stargatePoolNative || msg.sender != endpointV2) {
            revert KannonV1Library.KannonV1_Unauthorized();
        }
        uint256 amountLD = OFTComposeMsgCodec.amountLD(_message);
        uint32 srcEid = OFTComposeMsgCodec.srcEid(_message);
        bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

        (bytes1 transactionType, bytes memory data) = abi.decode(_composeMessage, (bytes1, bytes));
        if (transactionType == 0x00) {
            TokenLiquidityParams memory params = abi.decode(data, (TokenLiquidityParams));
            params.ethAmount = amountLD;
            address tokenAddress = _createTokenAndAddLiquidity(params);
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
            revert KannonV1Library.KannonV1_InvalidInput();
        }
    }

    function _lzComposeSwapExactETHForTokens(address _tokenAddress, uint256 _amount, address _recipient, uint32 _srcEid)
        internal
        returns (uint256 amountOut)
    {
        if (_amount == 0) revert KannonV1Library.KannonV1_InsufficientFunds();

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
                    revert KannonV1Library.KannonV1_TransferFailed();
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
            revert KannonV1Library.KannonV1_WETH9Failed();
        }
    }

    function _unwrapETH(uint256 amount) internal {
        try IWETH9(WETH9).withdraw(amount) {}
        catch {
            revert KannonV1Library.KannonV1_WETH9Failed();
        }
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
                revert KannonV1Library.KannonV1_TransferFailed();
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
            revert KannonV1Library.KannonV1_InvalidParameters();
        }
        if (amount == 0) {
            revert KannonV1Library.KannonV1_InvalidInput();
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
            revert KannonV1Library.KannonV1_InsufficientFundsForCrossMessage();
        }
        if (amount - messagingFee.nativeFee < MIN_AMOUNT) {
            revert KannonV1Library.KannonV1_InsufficientFundsForCrossMessage();
        }
        sendParam.amountLD = amount - messagingFee.nativeFee;

        IStargate(stargatePoolNative).sendToken{value: amount}(sendParam, messagingFee, recipient);
    }

    function swapExactETHForTokens(address tokenAddress) external payable returns (uint256) {
        if (msg.value == 0) revert KannonV1Library.KannonV1_InsufficientFunds();
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
        KannonV1Library.TokenUpdateData memory data =
            KannonV1Library.getTokenUpdateData(tokenAddress, WETH9, tokenInfo[tokenAddress].pool);

        emit TokenUpdate(
            tokenAddress,
            tokenInfo[tokenAddress].creator,
            data.sqrtPriceX96,
            data.tokenPrice,
            data.ethReserve,
            data.tokenReserve,
            data.totalSupply,
            tokenInfo[tokenAddress].lockedLiquidityPercentage,
            block.timestamp
        );
    }

    function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /* tokenId*/ bytes calldata)
        external
        view
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
