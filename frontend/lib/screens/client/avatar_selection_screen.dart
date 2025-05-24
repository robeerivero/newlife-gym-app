import 'package:flutter/material.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String? initialGender;
  final String? initialSkinColor;
  final String? initialHair;
  final String? initialClothing;

  const AvatarSelectionScreen({
    Key? key,
    this.initialGender,
    this.initialSkinColor,
    this.initialHair,
    this.initialClothing,
  }) : super(key: key);

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late String gender;
  late String skinColor;
  late String hair;
  late String clothing;

  @override
  void initState() {
    super.initState();
    gender = widget.initialGender ?? 'male';
    skinColor = widget.initialSkinColor ?? 'light';
    hair = widget.initialHair ?? 'short_brown';
    clothing = widget.initialClothing ?? 'casual1';
  }

  String get baseAsset => 'assets/avatar/base/${gender}_$skinColor.png';
  String get hairAsset => 'assets/avatar/hair/$hair.png';
  String get clothingAsset => 'assets/avatar/clothing/$clothing.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Elige tu avatar"),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Avatar Preview
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(baseAsset, width: 120, fit: BoxFit.contain),
                  Image.asset(hairAsset, width: 120, fit: BoxFit.contain),
                  Image.asset(clothingAsset, width: 120, fit: BoxFit.contain),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Género
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Chico"),
                  selected: gender == 'male',
                  onSelected: (_) => setState(() => gender = 'male'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Chica"),
                  selected: gender == 'female',
                  onSelected: (_) => setState(() => gender = 'female'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Color de piel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Piel clara"),
                  selected: skinColor == 'light',
                  onSelected: (_) => setState(() => skinColor = 'light'),
                  backgroundColor: Colors.brown[100],
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Piel media"),
                  selected: skinColor == 'medium',
                  onSelected: (_) => setState(() => skinColor = 'medium'),
                  backgroundColor: Colors.brown[300],
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Piel oscura"),
                  selected: skinColor == 'dark',
                  onSelected: (_) => setState(() => skinColor = 'dark'),
                  backgroundColor: Colors.brown[600],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Peinado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Corto castaño"),
                  selected: hair == 'short_brown',
                  onSelected: (_) => setState(() => hair = 'short_brown'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Corto rubio"),
                  selected: hair == 'short_blonde',
                  onSelected: (_) => setState(() => hair = 'short_blonde'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Largo castaño"),
                  selected: hair == 'long_brown',
                  onSelected: (_) => setState(() => hair = 'long_brown'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Largo rubio"),
                  selected: hair == 'long_blonde',
                  onSelected: (_) => setState(() => hair = 'long_blonde'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Ropa
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Casual 1"),
                  selected: clothing == 'casual1',
                  onSelected: (_) => setState(() => clothing = 'casual1'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Casual 2"),
                  selected: clothing == 'casual2',
                  onSelected: (_) => setState(() => clothing = 'casual2'),
                ),
              ],
            ),

            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Confirmar avatar"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.of(context).pop({
                  'gender': gender,
                  'skinColor': skinColor,
                  'hair': hair,
                  'clothing': clothing,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
