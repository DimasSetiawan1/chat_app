abstract class EntityModel<T> {
  T get toEntity;
  Map<String, dynamic> toJson();
}