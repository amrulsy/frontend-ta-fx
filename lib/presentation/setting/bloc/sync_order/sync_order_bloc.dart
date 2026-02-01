import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:project_ta/data/repositories/order_repository.dart';

part 'sync_order_bloc.freezed.dart';
part 'sync_order_event.dart';
part 'sync_order_state.dart';

class SyncOrderBloc extends Bloc<SyncOrderEvent, SyncOrderState> {
  final OrderRepository orderRepository;

  SyncOrderBloc(this.orderRepository) : super(const _Initial()) {
    on<_SendOrder>((event, emit) async {
      emit(const SyncOrderState.loading());

      final result = await orderRepository.syncOrders();

      result.fold(
        (message) => emit(SyncOrderState.error(message)),
        (successMessage) => emit(const SyncOrderState.success()),
      );
    });
  }
}
