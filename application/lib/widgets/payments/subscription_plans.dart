import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/subscription.dart';

class SubscriptionPlans extends StatefulWidget {
  const SubscriptionPlans({super.key});

  @override
  State<SubscriptionPlans> createState() => _SubscriptionPlansState();
}

class _SubscriptionPlansState extends State<SubscriptionPlans> {
  String? _selectedPlanId;
  String? _selectedPaymentMethodId;

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        if (paymentProvider.isLoading && paymentProvider.subscriptionPlans.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (paymentProvider.subscriptionPlans.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subscriptions, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No subscription plans available',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current subscription status
              if (paymentProvider.activeSubscriptions.isNotEmpty)
                _buildCurrentSubscriptionCard(paymentProvider),
              
              const SizedBox(height: 24),
              
              // Available plans
              const Text(
                'Available Plans',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Plans grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: paymentProvider.subscriptionPlans.length,
                itemBuilder: (context, index) {
                  final plan = paymentProvider.subscriptionPlans[index];
                  return _buildPlanCard(plan, paymentProvider);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Payment methods selection
              if (_selectedPlanId != null)
                _buildPaymentMethodSelection(paymentProvider),
              
              const SizedBox(height: 24),
              
              // Subscribe button
              if (_selectedPlanId != null && _selectedPaymentMethodId != null)
                _buildSubscribeButton(paymentProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentSubscriptionCard(PaymentProvider paymentProvider) {
    final activeSubscription = paymentProvider.activeSubscriptions.first;
    final plan = paymentProvider.subscriptionPlans
        .where((p) => p.id == activeSubscription.planId)
        .firstOrNull;

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Current Subscription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (plan != null) ...[
              Text(
                plan.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                plan.formattedPrice,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Expires: ${_formatDate(activeSubscription.endDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, PaymentProvider paymentProvider) {
    final isSelected = _selectedPlanId == plan.id;
    final isPopular = plan.isPopular;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPlanId = plan.id;
            _selectedPaymentMethodId = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                plan.formattedPrice,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              // Features
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection(PaymentProvider paymentProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (paymentProvider.paymentMethods.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.payment, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No payment methods available'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to add payment method
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Add payment method feature coming soon'),
                        ),
                      );
                    },
                    child: const Text('Add Payment Method'),
                  ),
                ],
              ),
            ),
          )
        else
          ...paymentProvider.paymentMethods.map((method) => Card(
            child: RadioListTile<String>(
              title: Text(method.displayName),
              subtitle: Text(method.type.name.toUpperCase()),
              value: method.id,
              groupValue: _selectedPaymentMethodId,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethodId = value;
                });
              },
            ),
          )),
      ],
    );
  }

  Widget _buildSubscribeButton(PaymentProvider paymentProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: paymentProvider.isLoading
            ? null
            : () => _subscribeToPlan(paymentProvider),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: paymentProvider.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Subscribe Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _subscribeToPlan(PaymentProvider paymentProvider) async {
    if (_selectedPlanId == null || _selectedPaymentMethodId == null) return;

    final subscription = await paymentProvider.createSubscription(
      planId: _selectedPlanId!,
      paymentMethodId: _selectedPaymentMethodId!,
    );

    if (subscription != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reset selection
      setState(() {
        _selectedPlanId = null;
        _selectedPaymentMethodId = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
