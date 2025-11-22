import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const MidtransPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  late final WebViewController? _controller;
  bool _isLoading = true;
  String _pageTitle = 'Pembayaran';
  bool _webPaymentWindowOpened = false;
  final _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _openWebPayment();
    } else {
      _initializeWebView();
    }
  }

  void _openWebPayment() {
    print('🌐 Opening Midtrans payment in new window: ${widget.paymentUrl}');

    // Buka payment URL di browser
    launchUrl(Uri.parse(widget.paymentUrl),
        mode: LaunchMode.externalApplication);

    setState(() {
      _webPaymentWindowOpened = true;
      _isLoading = false;
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkPaymentStatus(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            _controller?.getTitle().then((title) {
              if (title != null) {
                setState(() {
                  _pageTitle = title;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    print('🔍 Checking URL: $url');

    // Success patterns
    if (url.contains('status_code=200') ||
        url.contains('/finish') ||
        url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture') ||
        url.contains('transaction_status=success')) {
      print('✅ Payment SUCCESS detected from URL');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(
              context, {'status': 'success', 'order_id': widget.orderId});
        }
      });
    }
    // Pending patterns
    else if (url.contains('status_code=201') ||
        url.contains('transaction_status=pending')) {
      print('⏳ Payment PENDING detected from URL');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(
              context, {'status': 'pending', 'order_id': widget.orderId});
        }
      });
    }
    // Failed patterns
    else if (url.contains('status_code=202') ||
        url.contains('/error') ||
        url.contains('transaction_status=deny') ||
        url.contains('transaction_status=cancel') ||
        url.contains('transaction_status=expire') ||
        url.contains('transaction_status=failure')) {
      print('❌ Payment FAILED detected from URL');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(
              context, {'status': 'failed', 'order_id': widget.orderId});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Untuk web: tampilkan instruksi manual
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran Midtrans'),
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Halaman pembayaran telah dibuka di tab baru',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Silakan selesaikan pembayaran di tab tersebut.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Setelah selesai, pilih status pembayaran:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Tampilkan loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Force update payment ke success
                    final result = await _paymentService
                        .forcePaymentSuccess(widget.orderId);

                    // Tutup loading dialog
                    if (mounted) Navigator.pop(context);

                    // Return result
                    if (mounted) {
                      if (result['success'] == true) {
                        Navigator.pop(context, {
                          'status': 'success',
                          'order_id': widget.orderId,
                          'forced': true,
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal update: ${result['message']}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Pembayaran Berhasil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'status': 'pending',
                      'order_id': widget.orderId,
                    });
                  },
                  icon: const Icon(Icons.pending),
                  label: const Text('Pembayaran Pending'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'status': 'cancelled',
                      'order_id': widget.orderId,
                    });
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Batalkan'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Order ID: ${widget.orderId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Untuk mobile: gunakan WebView
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showCancelDialog,
        ),
        actions: [
          // Tombol "Selesai" untuk manual confirm setelah bayar
          if (!_isLoading)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi Pembayaran'),
                    content: const Text(
                      'Apakah Anda sudah menyelesaikan pembayaran?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Belum'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // tutup dialog
                          Navigator.pop(context, {
                            'status': 'success',
                            'order_id': widget.orderId,
                          });
                        },
                        child: const Text('Sudah'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Selesai',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan proses pembayaran?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'status': 'cancelled',
                'order_id': widget.orderId,
              });
            },
            child:
                const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
