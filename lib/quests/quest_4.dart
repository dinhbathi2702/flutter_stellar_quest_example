import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest4 extends StatefulWidget {
  const Quest4({super.key});

  @override
  State<Quest4> createState() => _Quest4State();
}

class _Quest4State extends State<Quest4> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  final usdcAsset = Asset.createNonNativeAsset(
      'USDC', 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5');
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
              onPressed: _createPassiveSellOffer,
              child: const Text('Create Passive Sell Offer')),
        ),
      ],
    ));
  }

  _createPassiveSellOffer() async {
    try {
      final KeyPair questKeypair = _getQuestKey();
      final transactionBuilder = await _getTransactionBuilder(questKeypair);

      //Manage Buy Offer
      final manageBuyOfferOperation =
          ManageBuyOfferOperationBuilder(Asset.NATIVE, usdcAsset, '100', '10')
              .setSourceAccount(questKeypair.accountId)
              .build();
      transactionBuilder.addOperation(manageBuyOfferOperation);

      //Manage Sell Offer
      final manageSellOfferOperation = ManageSellOfferOperationBuilder(
              Asset.NATIVE, usdcAsset, '1000', '0.1')
          .setSourceAccount(questKeypair.accountId)
          .build();
      transactionBuilder.addOperation(manageSellOfferOperation);

      //Create Passive Sell Offer
      final passiveSellOfferOperation = CreatePassiveSellOfferOperationBuilder(
              Asset.NATIVE, usdcAsset, '1000', '0.1')
          .setSourceAccount(questKeypair.accountId)
          .build();
      final transaction =
          transactionBuilder.addOperation(passiveSellOfferOperation).build();

      transaction.sign(questKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print(
              "account ${response.successfulTransaction?.sourceAccountMuxedId} created");
        }
      }
    } catch (ex) {
      debugPrint('🔎 : $ex ❗️');
    }
  }

  KeyPair _getQuestKey() {
    final secretKey = _secretKeyController.text;
    final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
    return questKeypair;
  }

  Future<TransactionBuilder> _getTransactionBuilder(
      KeyPair questKeypair) async {
    ///funded on the testnet

    bool questKeypairFunded =
        await FriendBot.fundTestAccount(questKeypair.accountId);
    if (kDebugMode) {
      print("questKeypair: $questKeypairFunded");
    }

    ///set up the server and account that will be used to build and submit the transaction.
    final AccountResponse questAccount =
        await sdk.accounts.account(questKeypair.accountId);

    TransactionBuilder transaction = TransactionBuilder(
      questAccount,
    ).addOperation(ChangeTrustOperation(usdcAsset, '100'));
    return transaction;
  }
}
