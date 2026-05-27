import 'package:flutter/material.dart';

class AdminEditProfilePage extends StatefulWidget {
  final String title;
  final String initialValue;
  final IconData icon;
  final Future<void> Function(String)
  onSaveCallback; // Dynamic callback to backend handler

  const AdminEditProfilePage({
    super.key,
    required this.title,
    required this.initialValue,
    required this.icon,
    required this.onSaveCallback,
  });

  @override
  State<AdminEditProfilePage> createState() => _AdminEditProfilePageState();
}

class _AdminEditProfilePageState extends State<AdminEditProfilePage> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final Color brandMaroon = const Color(0xFF8B0000);
  final Color backgroundBeige = const Color(0xFFFDF8F0);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        // Execute the database document modification
        await widget.onSaveCallback(_controller.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.title} updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, _controller.text.trim());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update ${widget.title.toLowerCase()}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: brandMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit ${widget.title}",
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: brandMaroon,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveChanges,
                  child: Text(
                    "SAVE",
                    style: TextStyle(
                      color: brandMaroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update your ${widget.title.toLowerCase()} below.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _controller,
                obscureText: widget.title.contains("Password"),
                cursorColor: brandMaroon,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(widget.icon, color: brandMaroon),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter new ${widget.title.toLowerCase()}",
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: brandMaroon, width: 2),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter your ${widget.title.toLowerCase()}'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
