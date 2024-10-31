import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest3 extends StatefulWidget {
  const Quest3({super.key});

  @override
  State<Quest3> createState() => _Quest3State();
}

class _Quest3State extends State<Quest3> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;
  bool _isConnecting = false;

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
              onPressed: _isConnecting ? null : _changeTrust,
              child: const Text('Change Trust'),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _changeTrust() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final String secretKey = _secretKeyController.text;

      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      final KeyPair issuerKeypair = KeyPair.random();

      await _fundAccount(questKeypair.accountId, 'questKeypair');
      await _fundAccount(issuerKeypair.accountId, 'destinationKeypair');

      final Asset santaAsset =
          Asset.create("", 'SANTA', issuerKeypair.accountId);

      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);
      final transactionBuilder = ChangeTrustOperationBuilder(santaAsset, '100')
          .setSourceAccount(questKeypair.accountId)
          .setMuxedSourceAccount(MuxedAccount(questAccount.accountId, null))
          .build();

      final Transaction transaction = TransactionBuilder(questAccount)
          .addOperation(transactionBuilder)
          .build();

      transaction.sign(questKeypair, Network.TESTNET);
      final SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        if (kDebugMode) {
          print("Account ${questKeypair.accountId} Change Trust successfully.");
        }
      } else {
        if (kDebugMode) {
          print("Transaction failed: ${response.envelopeXdr}");
        }
      }
    } catch (ex) {
      if (kDebugMode) {
        print("Error occurred: $ex");
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _fundAccount(String accountId, String accountType) async {
    final bool funded = await FriendBot.fundTestAccount(accountId);
    if (kDebugMode) {
      print("$accountType funded: $funded");
    }
  }
}
