import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest5 extends StatefulWidget {
  const Quest5({super.key});

  @override
  State<Quest5> createState() => _Quest5State();
}

class _Quest5State extends State<Quest5> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  late KeyPair issuerKeypair;
  late KeyPair distributorKeypair;
  late KeyPair destinationKeypair;
  late Asset pathAssetSend;
  late Asset pathAssetReceive;
  @override
  void initState() {
    super.initState();
    issuerKeypair = KeyPair.random();
    distributorKeypair = KeyPair.random();
    destinationKeypair = KeyPair.random();
    pathAssetSend = Asset.createNonNativeAsset('PATH', issuerKeypair.accountId);
    pathAssetReceive =
        Asset.createNonNativeAsset('PATH', issuerKeypair.accountId);
  }

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
        title: 'Path Payment',
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
                      onPressed: _pathPaymentStrictSendOperationBuilder,
                      child: const Text('Path Payment Strict Send')),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: _pathPaymentStrictReceiveOperationBuilder,
                      child: const Text('Path Payment Strict Receive')),
                ),
              ],
            ),
          ],
        ));
  }

  _pathPaymentStrictSendOperationBuilder() async {
    try {
      final KeyPair questKeypair = _getQuestKey();

      final transactionBuilder = await _getTransactionBuilder(questKeypair);

      //Strict Send
      final pathPaymentStrictSendOperation =
          PathPaymentStrictSendOperationBuilder(Asset.NATIVE, '100',
                  destinationKeypair.accountId, pathAssetSend, '100')
              .build();
      final transaction = transactionBuilder
          .addOperation(pathPaymentStrictSendOperation)
          .build();

      transaction.sign(questKeypair, Network.TESTNET);
      transaction.sign(issuerKeypair, Network.TESTNET);
      transaction.sign(distributorKeypair, Network.TESTNET);
      transaction.sign(destinationKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print("extras ${response.extras} ");
          print(response.extras);
        }
      } else {
        debugPrint('resultXdr: ${response.resultXdr}');
        debugPrint('envelopeXdr: ${response.envelopeXdr}');
      }
    } catch (ex) {
      debugPrint('🔎 : $ex ❗️');
    }
  }

  _pathPaymentStrictReceiveOperationBuilder() async {
    try {
      final KeyPair questKeypair = _getQuestKey();

      final transactionBuilder = await _getTransactionBuilder(questKeypair);

//Strict Send
      final pathPaymentStrictSendOperation =
          PathPaymentStrictReceiveOperationBuilder(pathAssetSend, '450',
                  questKeypair.accountId, Asset.NATIVE, '450')
              .setSourceAccount(destinationKeypair.accountId)
              .build();
      final transaction = transactionBuilder
          .addOperation(pathPaymentStrictSendOperation)
          .build();

      transaction.sign(questKeypair, Network.TESTNET);
      transaction.sign(issuerKeypair, Network.TESTNET);
      transaction.sign(distributorKeypair, Network.TESTNET);
      transaction.sign(destinationKeypair, Network.TESTNET);

      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print(
              "account ${response.successfulTransaction?.sourceAccountMuxedId} created");
        }
      } else {
        debugPrint(response.resultXdr);
        debugPrint(response.envelopeXdr);
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

  Future<TransactionBuilder> _getTransactionBuilder(KeyPair questKeypair,
      {bool isReceive = false}) async {
    if (kDebugMode) {
      print("questKeyId: ${questKeypair.accountId}");
      print("issuerKeyId: ${issuerKeypair.accountId}");
      print("distributorKeyId: ${distributorKeypair.accountId}");
      print("destinationKeyId: ${destinationKeypair.accountId}");
    }

    ///funded on the testnet
    if (isReceive == false) {
      bool questKeypairFunded =
          await FriendBot.fundTestAccount(questKeypair.accountId);
      bool issuerKeypairFunded =
          await FriendBot.fundTestAccount(issuerKeypair.accountId);
      bool distributorKeypairFunded =
          await FriendBot.fundTestAccount(distributorKeypair.accountId);
      bool destinationKeypairFunded =
          await FriendBot.fundTestAccount(destinationKeypair.accountId);
      if (kDebugMode) {
        print("questKeypair: $questKeypairFunded");
        print("issuerKeypair: $issuerKeypairFunded");
        print("distributorKeypair: $distributorKeypairFunded");
        print("destinationKeypair: $destinationKeypairFunded");
      }
    }

    ///set up the server and account that will be used to build and submit the transaction.
    final AccountResponse questAccount =
        await sdk.accounts.account(questKeypair.accountId);

    final destinationChangeTrustOperation =
        ChangeTrustOperationBuilder(pathAssetSend, '100')
            .setSourceAccount(destinationKeypair.accountId)
            .build();
    final distributorKeypairChangeTrustOperation =
        ChangeTrustOperationBuilder(pathAssetSend, '100')
            .setSourceAccount(distributorKeypair.accountId)
            .build();
    final paymentOperation = PaymentOperationBuilder(
            distributorKeypair.accountId, pathAssetSend, '1000')
        .setSourceAccount(issuerKeypair.accountId)
        .build();

    final distributorKeypairCreatePassiveSellOffer1 =
        CreatePassiveSellOfferOperationBuilder(
                pathAssetSend, pathAssetSend, '100', '1')
            .setSourceAccount(distributorKeypair.accountId)
            .build();
    final distributorKeypairCreatePassiveSellOffer2 =
        CreatePassiveSellOfferOperationBuilder(
                pathAssetSend, pathAssetSend, '100', '1')
            .setSourceAccount(distributorKeypair.accountId)
            .build();

    TransactionBuilder transaction = TransactionBuilder(
      questAccount,
    )
        .addOperation(destinationChangeTrustOperation)
        .addOperation(distributorKeypairChangeTrustOperation)
        .addOperation(paymentOperation)
        .addOperation(distributorKeypairCreatePassiveSellOffer1)
        .addOperation(distributorKeypairCreatePassiveSellOffer2);
    return transaction;
  }
}
