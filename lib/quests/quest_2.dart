import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest2 extends StatefulWidget {
  const Quest2({super.key});

  @override
  State<Quest2> createState() => _Quest2State();
}

class _Quest2State extends State<Quest2> {
  final TextEditingController _secretKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String hintText, TextEditingController controller) {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hintText,
      ),
      controller: controller,
    );
  }

  Future<bool> _fundAccount(KeyPair keypair) async {
    return await FriendBot.fundTestAccount(keypair.accountId);
  }

  Future<void> _payment() async {
    try {
      final secretKey = _secretKeyController.text;

      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      final KeyPair destinationKeypair = KeyPair.random();

      bool questKeypairFunded = await _fundAccount(questKeypair);
      bool destinationKeypairFunded = await _fundAccount(destinationKeypair);

      if (kDebugMode) {
        print("questKeypairFunded: $questKeypairFunded");
        print("destinationKeypairFunded: $destinationKeypairFunded");
      }

      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);
      Transaction transaction = TransactionBuilder(questAccount)
          .addOperation(PaymentOperation(
              MuxedAccount(destinationKeypair.accountId, null),
              Asset.NATIVE,
              '100'))
          .build();

      transaction.sign(questKeypair, Network.TESTNET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        debugPrint("Account ${questKeypair.accountId} paid successfully");
        // Optionally show a success message to the user
      } else {
        // Handle failure response
        debugPrint("Transaction failed: ${response.envelopeXdr}");
      }
    } catch (ex) {
      debugPrint("Error: $ex");
      // Optionally show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      child: Column(
        children: [
          _buildTextField('Secret key', _secretKeyController),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _payment,
              child: const Text('Payment'),
            ),
          ),
        ],
      ),
    );
  }
}
