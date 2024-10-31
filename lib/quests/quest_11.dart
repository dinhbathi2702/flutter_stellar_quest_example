import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/common/converter.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest11 extends StatefulWidget {
  const Quest11({super.key});

  @override
  State<Quest11> createState() => _Quest11State();
}

class _Quest11State extends State<Quest11> {
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;

  @override
  void dispose() {
    _secretKeyController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
        child: Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Public Key',
          ),
          controller: _publicKeyController,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Secret key',
          ),
          controller: _secretKeyController,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
              onPressed: _bumpSequence, child: const Text('Bump Sequence')),
        )
      ],
    ));
  }

  _bumpSequence() async {
    try {
      final secretKey = _secretKeyController.text;
      final publicKey = _publicKeyController.text;

      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);

      Transaction transaction = TransactionBuilder(questAccount)
          .addOperation(BumpSequenceOperationBuilder(
                  BigInt.from(questAccount.sequenceNumber.toInt() + 100))
              .build())
          .build();

      transaction.sign(questKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        debugPrint("submitTransaction success ${response.success} ");

        final AccountResponse bumpedAccount =
            await sdk.accounts.account(publicKey);

        Transaction nextTransaction = TransactionBuilder(bumpedAccount)
            .addOperation(ManageDataOperation(
                'sequence', convertStringToUint8List('bumped')))
            .build();

        nextTransaction.sign(questKeypair, Network.TESTNET);

        SubmitTransactionResponse nextResponse =
            await sdk.submitTransaction(nextTransaction);
        if (nextResponse.success) {
          debugPrint(
              'Transaction Bump Sequence Successful! Hash: ${nextResponse.hash}');
        }
      }
    } catch (ex) {
      debugPrint('ex: $ex');
    }
  }
}
