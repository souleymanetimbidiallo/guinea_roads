import 'package:flutter/material.dart';
import 'package:guinea_roads/controllers/profil_controller.dart';
import 'package:guinea_roads/models/profil_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'full_photo_page.dart';
import 'dart:io';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

final TextEditingController _passwordController = TextEditingController();

class _ProfilPageState extends State<ProfilPage> {
  final ProfilController _controller = ProfilController();

  String? _errorMessage;
  File? _image;

  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    fetchPhotoUrlFromFirebaseAuth();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      await _controller.fetchUser();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la récupération des données utilisateur: $e';
      });
    } finally {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance.ref()
            .child('user_photos')
            .child('${user.uid}.jpg');
        UploadTask uploadTask = storageRef.putFile(_image!);

        TaskSnapshot taskSnapshot = await uploadTask;
        final photoUrl = await taskSnapshot.ref.getDownloadURL();

        await _controller.updateUserProfile({'photoUrl': photoUrl});
        await user.updatePhotoURL(photoUrl);

        await _fetchUserData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du téléchargement de l\'image: $e';
      });
    }
  }

  Future<void> _changePassword() async {
    String? oldPassword = await _getOldPassword();

    if (oldPassword != null) {
      String? newPassword = await _getNewPassword();

      if (newPassword != null) {
        if (newPassword == _confirmPassword) {
          try {
            await _controller.changePassword(newPassword);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mot de passe modifié avec succès')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de la modification du mot de passe: $e')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
          );
        }
      }
    }
  }

  Future<String?> _getOldPassword() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? password;
        return AlertDialog(
          title: const Text('Ancien mot de passe'),
          content: TextField(
            obscureText: true,
            onChanged: (value) => password = value,
            decoration: const InputDecoration(
                hintText: 'Entrez votre ancien mot de passe'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(password);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  String? _newPassword;
  String? _confirmPassword;

  Future<String?> _getNewPassword() async {
    _newPassword = null;
    _confirmPassword = null;

    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Nouveau mot de passe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _newPassword = value;
                      });
                    },
                    decoration: const InputDecoration(
                        hintText: 'Entrez votre nouveau mot de passe'),
                  ),
                  TextField(
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _confirmPassword = value;
                      });
                    },
                    decoration: const InputDecoration(
                        hintText: 'Confirmez votre nouveau mot de passe'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    bool passwordsMatch = _newPassword != null && _confirmPassword != null && _newPassword == _confirmPassword;
                    Navigator.of(context).pop(passwordsMatch);
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (isConfirmed != null && isConfirmed) {
      return _newPassword;
    } else {
      return null;
    }
  }

  Future<void> _confirmLogout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vous déconnecter ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Oui'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (confirm) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // Fonction pour récupérer l'URL de la photo de profil
  void fetchPhotoUrlFromFirebaseAuth() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.photoURL != null) {
      setState(() {
        photoUrl = user.photoURL!;
      });
      print("URL de la photo de profil récupérée : $photoUrl"); // Pour vérifier l'URL
    } else {
      print('L\'utilisateur n\'est pas connecté ou l\'URL de la photo de profil n\'est pas disponible.');
    }
  }

  Future<void> _viewPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullPhotoPage(photoUrl: photoUrl),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'URL de l\'image est invalide')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    UserProfile? user = _controller.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
        appBar: AppBar(
        title: const Text('Profil'),
    ),
    body: SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Options de photo'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo),
                            title: const Text('Voir la photo'),
                            onTap: () {
                              print("Voir la photo tapped");
                              _viewPhoto();
                            },

                          ),
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('Modifier la photo'),
                            onTap: () {
                              _pickImage();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user.photoUrl ?? 'https://via.placeholder.com/150'),
                  ),
                  const SizedBox(height: 8), // Espacement entre le cercle de l'image et les options
                ],
              ),
            ),

          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(user.email),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('Historique des trajets'),
          ),
          ...user.history.map((item) => ListTile(
            title: Text(item),
            leading: const Icon(Icons.trip_origin),
          )),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              onTap: _updateUserProfile,
              leading: const Icon(Icons.edit),
              title: const Text('Mettre à jour le profil'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              onTap: _changePassword,
              leading: const Icon(Icons.lock),
              title: const Text('Changer le mot de passe'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              onTap: _confirmLogout,
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _updateUserProfile() async {
    // Logique pour mettre à jour le profil de l'utilisateur
  }
}


