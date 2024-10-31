import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest15 extends StatefulWidget {
  const Quest15({super.key});

  @override
  State<Quest15> createState() => _Quest15State();
}

class _Quest15State extends State<Quest15> {
  final TextEditingController secretTokenController = TextEditingController();
  final TextEditingController publicTokenController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
        child: Column(
      children: [
        TextField(
          controller: secretTokenController,
        ),
        TextField(
          controller: publicTokenController,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              ElevatedButton(onPressed: _clawbacks, child: const Text('Clawbacks')),
        )
      ],
    ));
  }

  _clawbacks() async {
    try {
      final secretKey = secretTokenController.text;
      final publicKey = publicTokenController.text;

      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      final KeyPair destinationKeypair = KeyPair.random();
      final AccountResponse questAccount =
          await sdk.accounts.account(publicKey);

      await FriendBot.fundTestAccount(questKeypair.accountId);
      await FriendBot.fundTestAccount(destinationKeypair.accountId);

      CreateAccountOperationBuilder createAccBuilder =
          CreateAccountOperationBuilder(destinationKeypair.accountId, "100");

      Transaction transaction = TransactionBuilder(questAccount)
          .addOperation(createAccBuilder.build())
          .build();

      transaction.sign(questKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print("account $publicKey created");
        }
      }
    } catch (ex) {
      debugPrint("ex: $ex");
    }
  }
}
