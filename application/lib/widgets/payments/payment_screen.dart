import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import 'subscription_plans.dart';
import 'payment_form.dart';
import 'payment_history.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize payment system
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Subscriptions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.subscriptions), text: 'Plans'),
            Tab(icon: Icon(Icons.payment), text: 'Payment'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          Consumer<PaymentProvider>(
            builder: (context, paymentProvider, child) {
              if (paymentProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => paymentProvider.initialize(),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PaymentProvider>(
        builder: (context, authProvider, paymentProvider, child) {
          // Check if user is authenticated
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please log in to access payments',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // Check payment gateway availability
          if (!paymentProvider.isPaymentGatewayAvailable) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment system is currently unavailable',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please try again later',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => paymentProvider.checkPaymentGatewayAvailability(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show error if any
          if (paymentProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${paymentProvider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      paymentProvider.clearError();
                      paymentProvider.initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Main content with tabs
          return TabBarView(
            controller: _tabController,
            children: const [
              SubscriptionPlans(),
              PaymentForm(),
              PaymentHistory(),
            ],
          );
        },
      ),
    );
  }
}
