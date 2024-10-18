// ignore_for_file: camel_case_types

import 'arceus.dart';

Arceus? currentInstance;

class BitValue {
  int get size => 0;
  late bitfield field;
  late int bitAddress;
  BitValue();

  void init(bitfield field, int bitAddress) {
    this.bitAddress = bitAddress;
    this.field = field;
  }
}

class pad extends BitValue {
  final int _size;

  @override
  int get size => _size;

  pad(this._size);
}

/// # class `flag`
/// ## A single bit value that acts like a boolean.
class flag extends BitValue {
  @override
  int get size => 1;

  flag();
}

/// # class `u2`
/// ## A two bit value that can represent four different values.
class u2 extends BitValue {
  @override
  int get size => 2;

  u2();
}

/// # class `u3`
/// ## A three bit value that can represent eight different values.
class u3 extends BitValue {
  @override
  int get size => 3;

  u3();
}

/// # class `u4`
/// ## A four bit value that can represent 16 different values.
class u4 extends BitValue {
  @override
  int get size => 4;

  u4();
}

/// # class `u5`
/// ## A five bit value that can represent 32 different values.
class u5 extends BitValue {
  @override
  int get size => 5;

  u5();
}

/// # class `u6`
/// ## A six bit value that can represent 64 different values.
class u6 extends BitValue {
  @override
  int get size => 6;

  u6();
}

/// # class `u7`
/// ## A seven bit value that can represent 128 different values.
class u7 extends BitValue {
  @override
  int get size => 7;

  u7();
}

class ByteValue {
  dynamic get value => null;
  int address;
  // ignore: unused_field
  late int? size;
  ByteValue(this.address, {int? size}) {
    if (size != null) {
      this.size = size;
    }
  }
}

class u8 extends ByteValue {
  @override
  int get value => _value;
  int _value;

  u8(super.address, this._value, {super.size}) {
    if (_value & 0xFF != _value) {
      throw RangeError.index(_value, 0xFF);
    }
  }

  factory u8.read(int address) {
    return u8(address, currentInstance!.bytes[address], size: 1);
  }
}

class u16 extends ByteValue {
  @override
  int get value => _value;
  int _value;
  u16(super.address, this._value, {super.size}) {
    if (_value & 0xFFFF != _value) {
      throw RangeError.index(_value, 0xFFFF);
    }
  }

  factory u16.read(int address) {
    return u16(
      address,
      (currentInstance!.bytes[address] << 8) |
          currentInstance!.bytes[address + 1],
      size: 2,
    );
  }
}

class u32 extends ByteValue {
  @override
  int get value => _value;
  int _value;
  u32(super.address, this._value, {super.size}) {
    if (_value & 0xFFFFFFFF != _value) {
      throw RangeError.index(_value, 0xFFFFFFFF);
    }
  }

  factory u32.read(int address) {
    return u32(
        address,
        (currentInstance!.bytes[address] << 24) |
            (currentInstance!.bytes[address + 1] << 16) |
            (currentInstance!.bytes[address + 2] << 8) |
            currentInstance!.bytes[address + 3],
        size: 4);
  }
}

class u64 extends ByteValue {
  @override
  int get value => _value;
  int _value;
  u64(super.address, this._value, {super.size}) {
    if (_value & 0xFFFFFFFFFFFFFFFF != _value) {
      throw RangeError.index(_value, 0xFFFFFFFFFFFFFFFF);
    }
  }

  factory u64.read(int address) {
    return u64(
        address,
        (currentInstance!.bytes[address] << 56) |
            (currentInstance!.bytes[address + 1] << 48) |
            (currentInstance!.bytes[address + 2] << 40) |
            (currentInstance!.bytes[address + 3] << 32) |
            (currentInstance!.bytes[address + 4] << 24) |
            (currentInstance!.bytes[address + 5] << 16) |
            (currentInstance!.bytes[address + 6] << 8) |
            currentInstance!.bytes[address + 7],
        size: 8);
  }
}

class str16 extends ByteValue {
  @override
  String get value => _value;
  String _value;
  str16(super.address, this._value, {super.size}) {
    if (_value.length > size!) {
      throw RangeError.index(_value.length, size);
    }
  }

  factory str16.read(int address, int size) {
    return str16(
      address,
      String.fromCharCodes(
          currentInstance!.bytes.sublist(address, address + size)),
      size: size,
    );
  }
}

class bitfield extends ByteValue {
  Map<String, BitValue> variables;
  bitfield(super.address, this.variables, {super.size});

  factory bitfield.read(int address, Map<String, BitValue> variables) {
    int currentAddress = 0;
    final field = bitfield(address, variables);
    for (var e in variables.keys) {
      variables[e]!.init(field, currentAddress);
      currentAddress += variables[e]!.size;
    }
    field.size = currentAddress;
    return field;
  }
}
