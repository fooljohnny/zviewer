import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment.dart';

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  PaymentStatus? _selectedStatus;
  PaymentType? _selectedType;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  void _loadPayments() {
    context.read<PaymentProvider>().loadPaymentHistory(
      page: _currentPage,
      limit: _pageSize,
      status: _selectedStatus,
      type: _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Column(
          children: [
            // Filters
            _buildFilters(paymentProvider),
            
            // Payment list
            Expanded(
              child: _buildPaymentList(paymentProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(PaymentProvider paymentProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Status filter
          Row(
            children: [
              const Text('Status: '),
              Expanded(
                child: DropdownButton<PaymentStatus?>(
                  value: _selectedStatus,
                  isExpanded: true,
                  hint: const Text('All Statuses'),
                  items: [
                    const DropdownMenuItem<PaymentStatus?>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...PaymentStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusDisplayName(status)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _currentPage = 1;
                    });
                    _loadPayments();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Type filter
          Row(
            children: [
              const Text('Type: '),
              Expanded(
                child: DropdownButton<PaymentType?>(
                  value: _selectedType,
                  isExpanded: true,
                  hint: const Text('All Types'),
                  items: [
                    const DropdownMenuItem<PaymentType?>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...PaymentType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeDisplayName(type)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      _currentPage = 1;
                    });
                    _loadPayments();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(PaymentProvider paymentProvider) {
    if (paymentProvider.isLoading && paymentProvider.payments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (paymentProvider.payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No payments found',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Your payment history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        await paymentProvider.refreshPaymentHistory();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: paymentProvider.payments.length + 1, // +1 for load more button
        itemBuilder: (context, index) {
          if (index == paymentProvider.payments.length) {
            return _buildLoadMoreButton(paymentProvider);
          }
          
          final payment = paymentProvider.payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment.status),
          child: Icon(
            _getStatusIcon(payment.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          payment.description ?? 'Payment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${payment.currency.toUpperCase()} ${payment.amount.toStringAsFixed(2)}'),
            Text(
              _formatDate(payment.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getStatusDisplayName(payment.status),
              style: TextStyle(
                color: _getStatusColor(payment.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              _getTypeDisplayName(payment.type),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  Widget _buildLoadMoreButton(PaymentProvider paymentProvider) {
    if (paymentProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          _currentPage++;
          _loadPayments();
        },
        child: const Text('Load More'),
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', payment.id),
              _buildDetailRow('Amount', '${payment.currency.toUpperCase()} ${payment.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Status', _getStatusDisplayName(payment.status)),
              _buildDetailRow('Type', _getTypeDisplayName(payment.type)),
              _buildDetailRow('Created', _formatDateTime(payment.createdAt)),
              if (payment.updatedAt != null)
                _buildDetailRow('Updated', _formatDateTime(payment.updatedAt!)),
              if (payment.description != null)
                _buildDetailRow('Description', payment.description!),
              if (payment.transactionId != null)
                _buildDetailRow('Transaction ID', payment.transactionId!),
              if (payment.subscriptionId != null)
                _buildDetailRow('Subscription ID', payment.subscriptionId!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String _getTypeDisplayName(PaymentType type) {
    switch (type) {
      case PaymentType.subscription:
        return 'Subscription';
      case PaymentType.oneTime:
        return 'One-time';
      case PaymentType.refund:
        return 'Refund';
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.completed:
        return Icons.check;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
