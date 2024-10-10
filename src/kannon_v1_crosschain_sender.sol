// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {OAppSender} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
// import {
//     MessagingParams,
//     MessagingFee,
//     MessagingReceipt
// } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {OAppCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";

// contract KannonV1CrossChainSender is OAppSender {
//     uint64 public version;

//     error NoEthSentForGas();

//     constructor(address _endpoint, uint64 _version) OAppCore(_endpoint, msg.sender) Ownable(msg.sender) {
//         version = _version;
//     }

//     function oAppVersion() public view override returns (uint64 senderVersion, uint64 receiverVersion) {
//         return (version, version);
//     }

//     function quote(uint32 _dstEid, address _receiver, bytes memory payload, bytes memory options, bool _payInLzToken)
//         public
//         view
//         returns (MessagingFee memory fee)
//     {
//         return _quote(_dstEid, payload, options, _payInLzToken);
//     }

//     event ReachedSendMessageFunction(string indexed message);

//     function sendMessage(
//         uint32 _dstEid,
//         address _receiver,
//         bytes memory options,
//         bytes memory payload,
//         MessagingFee memory _fee
//     ) public payable returns (MessagingReceipt memory receipt) {
//         // Verify that the sent value matches the quoted native fee
//         if (msg.value < _fee.nativeFee) {
//             revert NoEthSentForGas();
//         }
//         emit ReachedSendMessageFunction("reached 1");
//         // Send the message
//         receipt = _lzSend(_dstEid, payload, options, _fee, payable(msg.sender));
//         emit ReachedSendMessageFunction("i have finished running lzSend");
//         return receipt;
//     }
// }
