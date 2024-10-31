import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest13 extends StatefulWidget {
  const Quest13({super.key});

  @override
  State<Quest13> createState() => _Quest13State();
}

class _Quest13State extends State<Quest13> {
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
          child: ElevatedButton(
              onPressed: _claimableBalances,
              child: const Text('Claimable Balances')),
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

      transaction.sign(questKeypair, Network.TESTNET);

      //create a claimable balance from your Quest Account
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        debugPrint('Transaction Successful! Hash: ${response.hash}');
        debugPrint(
            'balanceId: ${response.getClaimableBalanceIdIdFromResult(0)}');

        await Future.delayed(const Duration(minutes: 5));
        debugPrint('Start Claim');
        bool claimantKeypairFunded =
            await FriendBot.fundTestAccount(claimantKeypair.accountId);
        debugPrint("claimantKeypair: $claimantKeypairFunded");

        final AccountResponse claimantAccount =
            await sdk.accounts.account(claimantKeypair.accountId);
        debugPrint('claimantAccount getAccount $claimantAccount');
        final balanceId = response.getClaimableBalanceIdIdFromResult(0) ?? '';
        Transaction claimTransaction = TransactionBuilder(claimantAccount)
            .addOperation(ClaimClaimableBalanceOperation(balanceId))
            .build();
        claimTransaction.sign(claimantKeypair, Network.TESTNET);
        debugPrint('claimantAccount sign');
        SubmitTransactionResponse nextResponse =
            await sdk.submitTransaction(claimTransaction);
        debugPrint('claimantAccount submitTransaction');

        if (nextResponse.success) {
          debugPrint(
              'Balance Successfully Claimed! Hash: ${nextResponse.hash}');
        } else {
          debugPrint(
              'Balance Claimed Fail ! envelopeXdr: ${nextResponse.envelopeXdr}');
          debugPrint(
              'Balance Claimed Fail ! resultXdr: ${nextResponse.resultXdr}');
        }
      }
    } catch (ex) {
      debugPrint('ex: $ex');
    }
  }
}
