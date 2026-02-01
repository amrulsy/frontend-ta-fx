import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:project_ta/data/datasources/auth_remote_datasource.dart';
import 'package:project_ta/data/datasources/auth_local_datasource.dart';

import '../../../../data/models/response/auth_response_model.dart';

part 'login_bloc.freezed.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRemoteDatasource authRemoteDatasource;
  final AuthLocalDatasource authLocalDatasource; // Injected dependency

  LoginBloc(this.authRemoteDatasource, this.authLocalDatasource)
    : super(const _Initial()) {
    on<_Login>((event, emit) async {
      emit(const _Loading());
      final response = await authRemoteDatasource.login(
        event.email,
        event.password,
      );
      response.fold((l) => emit(_Error(l)), (r) {
        // Architectural Fix: Save data in Bloc, not UI
        authLocalDatasource.saveAuthData(r);
        emit(_Success(r));
      });
    });
  }
}
