import 'package:flutter/material.dart';
import 'package:flutter_stellar_quest_example/widgets/base_page.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Quest1 extends StatefulWidget {
  const Quest1({super.key});

  @override
  State<Quest1> createState() => _Quest1State();
}

class _Quest1State extends State<Quest1> {
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final StellarSDK sdk = StellarSDK.TESTNET;

  static const String secretKeyHint = 'Secret key';
  static const String connectButtonText = 'Create Account';
  static const String accountCreatedMessage = 'Account created successfully';

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
          _buildTextField(_secretKeyController, secretKeyHint),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _createAccount,
              child: const Text(connectButtonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hint,
      ),
      controller: controller,
    );
  }

  Future<void> _createAccount() async {
    final String secretKey = _secretKeyController.text.trim();
    final String publicKey = _publicKeyController.text.trim();

    if (secretKey.isEmpty || publicKey.isEmpty) {
      debugPrint('Please enter both keys.');
      return;
    }

    try {
      final KeyPair questKeypair = KeyPair.fromSecretSeed(secretKey);
      final KeyPair newKeypair = KeyPair.random();
      final AccountResponse questAccount =
          await sdk.accounts.account(questKeypair.accountId);

      final CreateAccountOperationBuilder createAccBuilder =
          CreateAccountOperationBuilder(newKeypair.accountId, "1000");

      final Transaction transaction = TransactionBuilder(questAccount)
          .addOperation(createAccBuilder.build())
          .build();

      transaction.sign(questKeypair, Network.TESTNET);

      final SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      if (response.success) {
        debugPrint(accountCreatedMessage);
      } else {
        debugPrint('Transaction failed: ${response.envelopeXdr}');
      }
    } catch (ex) {
      debugPrint('Error: $ex');
    }
  }
}
