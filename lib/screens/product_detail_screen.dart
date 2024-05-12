import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  ProductDetailScreen({required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? productData;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() async {
    DocumentSnapshot snapshot = await _firestore.collection('products').doc(widget.productId).get();
    if (snapshot.exists) {
      setState(() {
        productData = snapshot;
      });
    }
  }

  void _deleteProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            child: Text('No'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () async {
              await _firestore.collection('products').doc(widget.productId).delete();
              Navigator.of(ctx).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back to the product list
            },
          ),
        ],
      ),
    );
  }

  void _changeProductName(BuildContext context, DocumentSnapshot product) {
    TextEditingController _nameController = TextEditingController(text: product['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Product Name'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('Submit'),
            onPressed: () async {
              if (_nameController.text.isNotEmpty && _nameController.text != product['name']) {
                await _firestore.collection('products').doc(widget.productId).update({'name': _nameController.text});
                Navigator.of(ctx).pop(); // Close the dialog
                _loadProduct(); // Reload product data to reflect the change immediately
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        leading: BackButton(),
      ),
      body: productData == null
          ? Center(child: CircularProgressIndicator())
          : buildProductDetails(context, productData!),
    );
  }

  Widget buildProductDetails(BuildContext context, DocumentSnapshot product) {
    List<dynamic> allergens = product['allergens'] as List<dynamic>;
    bool hasAllergens = allergens.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(product['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: Text('Potential Allergens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: hasAllergens
              ? Text(allergens.join(', '))
              : Text('There are no potential allergens in this product', style: TextStyle(color: Colors.green)),
        ),
        ListTile(
          title: Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text(product['ingredients'].join(', ')),
        ),
        ElevatedButton(
          onPressed: () => _changeProductName(context, product),
          child: Text('Change Name'),
        ),
        ElevatedButton(
          onPressed: () => _deleteProduct(context),
          child: Text('Delete Product'),
          style: ElevatedButton.styleFrom(primary: Colors.red),
        ),
      ],
    );
  }


  @override
  void dispose() {
    super.dispose();
  }
}
