import 'package:flutter/material.dart';
import '../pose/pose_camera_view.dart';
import '../pose/pose_model_catalog.dart';
import '../settings/camera_preference.dart';
import 'yoga_catalog.dart';
import 'yoga_pose_item.dart';

class YogaListPage extends StatefulWidget {
  const YogaListPage({super.key});

  @override
  State<YogaListPage> createState() => _YogaListPageState();
}

class _YogaListPageState extends State<YogaListPage> {
  PoseModelOption _selectedModel = kDefaultPoseModel;
  bool _useFrontCamera = true;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final chosen = await CameraPreference.hasChosenCamera();
    final useFront = await CameraPreference.loadUseFrontCamera();
    if (!mounted) return;
    setState(() {
      _useFrontCamera = useFront;
      _prefsLoaded = true;
    });
    if (!chosen && mounted) {
      await _promptCameraChoice();
    }
  }

  Future<void> _promptCameraChoice() async {
    final picked = await showCameraPreferenceDialog(context);
    if (!mounted || picked == null) return;
    await CameraPreference.saveUseFrontCamera(picked);
    setState(() => _useFrontCamera = picked);
  }

  Future<void> _setDefaultCamera(bool useFront) async {
    await CameraPreference.saveUseFrontCamera(useFront);
    if (mounted) setState(() => _useFrontCamera = useFront);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoga poses'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PoseModelOption>(
                    isExpanded: true,
                    value: _selectedModel,
                    items: [
                      for (final m in kPoseModelCatalog)
                        DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedModel = value);
                    },
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Choose a pose model, then open a yoga pose to test it.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Front'),
                  icon: Icon(Icons.camera_front_outlined),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Rear'),
                  icon: Icon(Icons.camera_rear_outlined),
                ),
              ],
              selected: {_useFrontCamera},
              onSelectionChanged: (sel) {
                final v = sel.first;
                _setDefaultCamera(v);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Default camera for practice (you can still switch on the pose screen).',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: kYogaPoseCatalog.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final pose = kYogaPoseCatalog[index];
                return ListTile(
                  title: Text(pose.displayName),
                  subtitle: pose.sanskritName != null
                      ? Text('${pose.sanskritName} · Code ${pose.id}')
                      : Text('Code ${pose.id}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPractice(context, pose),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openPractice(BuildContext context, YogaPoseItem pose) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => PoseCameraView(
          pose: pose,
          model: _selectedModel,
          useFrontCamera: _useFrontCamera,
        ),
      ),
    )
        .then((_) async {
      final useFront = await CameraPreference.loadUseFrontCamera();
      if (mounted) setState(() => _useFrontCamera = useFront);
    });
  }
}