import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncowe/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fireauth;
import 'package:syncowe/services/firestore/user_firestore.dart';

part 'current_user.g.dart';

@riverpod
class CurrentUser extends _$CurrentUser
{
  @override
  User? build()
  {
    var currenUserAsync = ref.listen(currentUserStreamProvider, setUser);
    switch(currenUserAsync)
    {
      case AsyncData(:final value):
      {
        if (value != null)
        {
          return value;
        }
      }
    }

    return null;
  }

  void setUser(AsyncValue<User?>? oldUser, AsyncValue<User?> user)
  {
    switch(user)
    {
      case AsyncData(:final value):
      {
        state = value;
      }
    }
  }
}


@riverpod
Stream<User?> currentUserStream(CurrentUserStreamRef ref)
{
  var fireAuthUser = ref.watch(currentFireAuthUserProvider);

  switch(fireAuthUser)
  {
    case AsyncData(:final value):
    {
      if(value != null)
      {
        UserFirestoreService userFirestoreService = ref.read(userFirestoreServiceProvider.notifier);
        return userFirestoreService.listenToUser(value.uid);
      }
      else
      {
        return const Stream.empty();
      }
    }
    default:
    {
      return const Stream.empty();
    }
  }
}

@riverpod
Stream<fireauth.User?> currentFireAuthUser(CurrentFireAuthUserRef ref)
{
  return fireauth.FirebaseAuth.instance.authStateChanges();
}