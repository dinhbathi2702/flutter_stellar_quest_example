import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest9 extends StatefulWidget {
  const Quest9({super.key});

  @override
  State<Quest9> createState() => _Quest9State();
}

class _Quest9State extends State<Quest9> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  final issuerKeypair = KeyPair.random();
  @override
  void dispose() {
    _secretKeyController.dispose();
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
            hintText: 'Secret key',
          ),
          controller: _secretKeyController,
        ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: _setFlags, child: const Text('Set Flags')),
            ),
          ],
        ),
      ],
    ));
  }

  KeyPair _getQuestKey() {
    final secretKey = _secretKeyController.text;
    final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
    return questKeypair;
  }

  _setFlags() async {
    try {
      final KeyPair questKeypair = _getQuestKey();

      if (kDebugMode) {
        print("questKeyId: ${questKeypair.accountId}");
        print("issuerKeyId: ${issuerKeypair.accountId}");
      }

      bool questKeypairFunded =
          await FriendBot.fundTestAccount(questKeypair.accountId);
      bool issuerKeypairFunded =
          await FriendBot.fundTestAccount(issuerKeypair.accountId);

      if (kDebugMode) {
        print("questKeypair: $questKeypairFunded");
        print("issuerKeypair: $issuerKeypairFunded");
      }

      ///set up the server and account that will be used to build and submit the transaction.

      final AccountResponse issuerAccount =
          await sdk.accounts.account(issuerKeypair.accountId);
      final controlledAsset =
          Asset.createNonNativeAsset('CONTROL', issuerKeypair.accountId);

      final transaction = TransactionBuilder(
        issuerAccount,
      )
          .addOperation(SetOptionsOperationBuilder().setSetFlags(3).build())
          .addOperation(ChangeTrustOperationBuilder(controlledAsset, '100')
              .setSourceAccount(questKeypair.accountId)
              .build())
          .addOperation(SetTrustLineFlagsOperationBuilder(
                  questKeypair.accountId, controlledAsset, 0, 1)
              .build())
          .addOperation(PaymentOperationBuilder(
                  questKeypair.accountId, controlledAsset, '100')
              .build())
          .addOperation(SetTrustLineFlagsOperationBuilder(
                  questKeypair.accountId, controlledAsset, 0, 0)
              .build())
          .build();
      transaction.sign(questKeypair, Network.TESTNET);
      transaction.sign(issuerKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print("account ${questKeypair.accountId} created");
        }
      }
    } catch (ex) {
      debugPrint('$ex');
    }
  }
}
