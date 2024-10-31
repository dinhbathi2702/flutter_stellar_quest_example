import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/common/converter.dart';
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
                  onPressed: _setOptions, child: const Text('Set Options')),
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

  _setOptions() async {
    try {
      final KeyPair questKeypair = _getQuestKey();
      final KeyPair secondSigner = KeyPair.random();
      final KeyPair thirdSigner = KeyPair.random();
      if (kDebugMode) {
        print("questKeyId: ${questKeypair.accountId}");
      }

      bool questKeypairFunded =
          await FriendBot.fundTestAccount(questKeypair.accountId);

      if (kDebugMode) {
        print("questKeypair: $questKeypairFunded");
      }

      ///set up the server and account that will be used to build and submit the transaction.
      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);

      //generate SingerKeys
      XdrSignerKey secondSignerKey =
          XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      secondSignerKey.ed25519 =
          XdrUint256(convertStringToUint8List(secondSigner.accountId));

      XdrSignerKey thirdSignerKey =
          XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      thirdSignerKey.ed25519 =
          XdrUint256(convertStringToUint8List(thirdSigner.accountId));

      final transaction = TransactionBuilder(
        questAccount,
      )
          .addOperation(SetOptionsOperationBuilder()
              .setMasterKeyWeight(1)
              .setLowThreshold(5)
              .setMediumThreshold(5)
              .setHighThreshold(5)
              .setHomeDomain('dinhbathi.glitch.me')
              .build())
          .addOperation(SetOptionsOperationBuilder()
              .setSigner(secondSignerKey, 2)
              .setHomeDomain('dinhbathi.glitch.me')
              .build())
          .addOperation(SetOptionsOperationBuilder()
              .setHomeDomain('dinhbathi.glitch.me')
              .setSigner(thirdSignerKey, 2)
              .build())
          .build();
      transaction.sign(questKeypair, Network.TESTNET);

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
