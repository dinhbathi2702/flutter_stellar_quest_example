import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest14 extends StatefulWidget {
  const Quest14({super.key});

  @override
  State<Quest14> createState() => _Quest14State();
}

class _Quest14State extends State<Quest14> {
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  final claimantKeypair = KeyPair.random();
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
          child:
              ElevatedButton(onPressed: _claimableBalances, child: const Text('Claimable Balances')),
        )
      ],
    ));
  }

  _claimableBalances() async {
    try {
      final secretKey = _secretKeyController.text;
      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      debugPrint("questKeyId: ${questKeypair.accountId}");
      debugPrint("questKeySecret: $secretKey");
      debugPrint("claimantKeyId: ${claimantKeypair.accountId}");
      debugPrint("claimantKeySecret: ${claimantKeypair.secretSeed}");

      bool questKeypairFunded =
          await FriendBot.fundTestAccount(questKeypair.accountId);

      debugPrint("questKeypair: $questKeypairFunded");

      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);

      final claimant = Claimant(claimantKeypair.accountId,
          Claimant.predicateNot(Claimant.predicateBeforeRelativeTime(300)));

      final questClaimant =
          Claimant(questKeypair.accountId, Claimant.predicateUnconditional());

      Transaction transaction = TransactionBuilder(questAccount)
          .addOperation(CreateClaimableBalanceOperation(
              [claimant, questClaimant], Asset.NATIVE, '100'))
          .build();

      transaction.sign(claimantKeypair, Network.TESTNET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        debugPrint('Transaction Successful! Hash: ${response.hash}');
      }
    } catch (ex) {
      debugPrint('ex: $ex');
    }
  }
}
