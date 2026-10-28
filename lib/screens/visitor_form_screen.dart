import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../core/config.dart';
import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'visitor_details_screen.dart';

/// Registration form; pass [visitor] to edit an existing record.
class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key, this.visitor});

  final Visitor? visitor;

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _purpose;
  String? _type;
  String? _project;
  bool _saving = false;

  bool get _isEdit => widget.visitor != null;

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  @override
  void initState() {
    super.initState();
    final v = widget.visitor;
    _name = TextEditingController(text: v?.name);
    _mobile = TextEditingController(text: v?.mobile);
    _email = TextEditingController(text: v?.email);
    _purpose = TextEditingController(text: v?.purpose);
    _type = AppConfig.visitorTypes.contains(v?.visitorType) ? v?.visitorType : null;
    _project = AppConfig.projects.contains(v?.project) ? v?.project : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final provider = context.read<VisitorProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isEdit) {
        await provider.updateVisitor(
          widget.visitor!,
          name: _name.text,
          mobile: _mobile.text,
          email: _email.text,
          visitorType: _type!,
          project: _project!,
          purpose: _purpose.text,
        );
        if (!mounted) return;
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Visitor updated successfully')));
      } else {
        final created = await provider.registerVisitor(
          name: _name.text,
          mobile: _mobile.text,
          email: _email.text,
          visitorType: _type!,
          project: _project!,
          purpose: _purpose.text,
        );
        if (!mounted) return;
        // Go to details, which shows the QR generated from the server-issued id.
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => VisitorDetailsScreen(visitorId: created.id)),
        );
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('${created.name} registered successfully')),
          );
      }
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, error: true);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Could not save visitor. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Visitor' : 'Register Visitor')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _name,
                  label: 'Visitor Name *',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Visitor name is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _mobile,
                  label: 'Mobile Number *',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Mobile number is required';
                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                      return 'Enter exactly 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _email,
                  label: 'Email (optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return null;
                    return _emailRegex.hasMatch(value) ? null : 'Enter a valid email address';
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Visitor Type *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: AppConfig.visitorTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v),
                  validator: (v) => v == null ? 'Select a visitor type' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _project,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Project *',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  items: AppConfig.projects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _project = v),
                  validator: (v) => v == null ? 'Select a project' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _purpose,
                  label: 'Purpose of Visit *',
                  icon: Icons.assignment_outlined,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Purpose of visit is required' : null,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: _isEdit ? 'Save Changes' : 'Register',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Cancel',
                  style: CustomButtonStyle.outlined,
                  onPressed: _saving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
