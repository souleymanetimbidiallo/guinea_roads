import 'package:guinea_roads/models/profil_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilController {
  UserProfile? user;
  bool isLoading = false;

  Future<void> fetchUser() async {
    print('Fetching user...');
    isLoading = true;
    try {
      User? currentUser = UserProfile.getCurrentUser();
      if (currentUser != null) {
        user = UserProfile(
          id: currentUser.uid,
          name: currentUser.displayName ?? '',
          email: currentUser.email ?? '',
          history: [], // Vous devrez remplir cette liste avec l'historique des trajets si vous le stockez quelque part
          photoUrl: currentUser.photoURL,
        );
        print('User fetched: ${user?.name}');
      } else {
        print('No user found');
      }
    } catch (e) {
      print('Error fetching user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    print('Updating user profile...');
    isLoading = true;
    try {
      String? userId = UserProfile.getCurrentUser()?.uid;
      if (userId != null) {
        await user?.updateUser(userId, data);
        user = await UserProfile.getUser(userId);
        print('User updated: ${user?.name}');
      }
    } catch (e) {
      print('Error updating user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> changePassword(String newPassword) async {
    print('Changing password...');
    try {
      User? currentUser = UserProfile.getCurrentUser();
      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        print('Password changed');
      }
    } catch (e) {
      print('Error changing password: $e');
      throw e;
    }
  }
}
