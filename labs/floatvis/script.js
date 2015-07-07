(function(global) {

function Floatvis(format, target) {
	this.format = format;
	this.target = target;
	this.buffer = new ArrayBuffer(format.octets);
	this.numbers = new this.format.type(this.buffer);
	this.octets = new Uint8Array(this.buffer);
	this.build();
	this.draw();
}

Floatvis.binary32 = {
	octets: 4,
	bits: 32,
	sign: 1,
	exponent: 8,
	significand: 23,
	bias: 127,
	specialExponent: 0xFF,
	maximumDigits: 9,
	quietBit: Math.pow(2, 22),
	type: Float32Array,
};

Floatvis.binary64 = {
	octets: 8,
	bits: 64,
	sign: 1,
	exponent: 11,
	significand: 52,
	bias: 1023,
	specialExponent: 0x7FF,
	maximumDigits: 17,
	quietBit: Math.pow(2, 51),
	type: Float64Array,
};

Floatvis.isLittleEndian = (function() {
	var buffer = new ArrayBuffer(2);
	var uint8 = new Uint8Array(buffer);
	var uint16 = new Uint16Array(buffer);
	uint16[0] = 0x1337;
	return uint8[1] == 0x13;
})();

Floatvis.prototype.build = function() {
	while (this.target.firstChild)
		this.target.removeChild(this.target.firstChild);

	this.view = {};

	var rows = this.view.rows = [];
	for (var i = 0; i < 4; i++) {
		var row = document.createElement('div');
		row.classList.add('row');
		this.target.appendChild(row);
		rows.push(row);
	}

	var entry = this.view.entry = document.createElement('input');
	entry.classList.add('entry');
	entry.addEventListener(
		'input',
		this.inputNumber.bind(this),
		false
	);
	rows[0].appendChild(entry);

	var equals = document.createElement('input');
	equals.classList.add('dead');
	equals.readOnly = true;
	equals.value = '=';
	rows[0].appendChild(equals);

	var info = this.view.info = document.createElement('input');
	info.classList.add('info');
	info.readOnly = true;
	rows[0].appendChild(info);

	var bits = this.view.bits = [];
	var integers = this.view.integers = [];
	var values = this.view.values = [];
	var bitIndex = this.format.bits - 1;

	['sign', 'exponent', 'significand'].forEach((function(part) {
		for (var i = 0; i < this.format[part]; i++) {
			var bit = document.createElement('input');
			bit.classList.add('bit');
			bit.classList.add(part);
			bit.maxLength = 1;
			highlightOnFocus(bit);
			bit.addEventListener(
				'input',
				this.inputBit.bind(this, bitIndex--),
				false
			);
			rows[1].appendChild(bit);
			bits.unshift(bit);
		}

		var integer = document.createElement('input');
		integer.classList.add(part);
		integer.readOnly = true;
		rows[2].appendChild(integer);
		integers.push(integer);

		var value = document.createElement('input');
		value.classList.add(part);
		value.readOnly = true;
		rows[3].appendChild(value);
		values.push(value);
	}).bind(this));
};

Floatvis.prototype.draw = function() {
	for (var i = 0; i < this.format.bits; i++)
		this.view.bits[i].value = this.getBit(i);
	this.view.info.value = this.getInfo();
	this.view.integers[0].value = this.getSign();
	this.view.integers[1].value = this.getExponent();
	this.view.integers[2].value = this.getSignificand();
	this.view.values[0].value = this.getSignValue();
	this.view.values[1].value = this.getExponentValue();
	this.view.values[2].value = this.getSignificandValue();
};

Floatvis.prototype.getNumber = function(/* optional */ buffer) {
	var numbers = buffer ? new this.format.type(buffer) : this.numbers;
	buffer = buffer || this.buffer;
	if (Floatvis.isLittleEndian) {
		var tempBuffer = buffer.slice();
		var tempNumbers = new this.format.type(tempBuffer);
		var tempOctets = new Uint8Array(tempBuffer);
		var octets = this.format.octets;
		for (var i = 0, temp; i < octets / 2; i++) {
			temp = tempOctets[i];
			tempOctets[i] = tempOctets[octets - i - 1];
			tempOctets[octets - i - 1] = temp;
		}
		return tempNumbers[0];
	}
	return numbers[0];
};

Floatvis.prototype.setNumber = function(number) {
	this.numbers[0] = number;
	if (Floatvis.isLittleEndian) {
		var octets = this.format.octets;
		for (var i = 0, temp; i < octets / 2; i++) {
			temp = this.octets[i];
			this.octets[i] = this.octets[octets - i - 1];
			this.octets[octets - i - 1] = temp;
		}
	}
};

Floatvis.prototype.inputNumber = function(event) {
	this.setNumber(event.target.value);
	this.draw();
};

Floatvis.prototype.getInfo = function() {
	var sign = this.getSign();
	var exponent = this.getExponent();
	var significand = this.getSignificand();
	var signText = sign ? 'negative ' : 'positive ';
	if (exponent == 0)
		if (significand == 0)
			return signText + 'zero';
		else
			return signText + 'subnormal'
	if (exponent == this.format.specialExponent) {
		if (significand == 0) {
			return signText + 'infinity';
		} else {
			if (significand < this.format.quietBit)
				return 'signalling NaN';
			else
				return 'quiet NaN';
		}
	}
	return signText + 'normal';
};

Floatvis.prototype.getBit = function(index, value) {
	var format = this.format;
	var octetIndex = (format.bits - 1 - index) / 8 | 0;
	var octet = this.octets[octetIndex];
	return octet >> index % 8 & 1;
};

Floatvis.prototype.setBit = function(index, value, /* optional */ array) {
	array = array || this.octets;
	var format = this.format;
	var octetIndex = (format.bits - 1 - index) / 8 | 0;
	var octet = array[octetIndex];
	octet &= (~(1 << index % 8)) & 0xFF;
	octet |= value << index % 8;
	array[octetIndex] = octet;
};

Floatvis.prototype.inputBit = function(index, event) {
	var goodInput = false;
	if (event.target.value == '0') {
		this.setBit(index, 0);
		goodInput = true;
	} else if (event.target.value == '1') {
		this.setBit(index, 1);
		goodInput = true;
	}
	this.draw();
	if (goodInput && index > 0)
		this.view.bits[index - 1].focus();
	else
		event.target.select();
};

Floatvis.prototype.getSign = function() {
	return this.getBit(this.format.bits - 1);
};

Floatvis.prototype.getSignValue = function() {
	var significand = this.getSignificand();
	var exponent = this.getExponent();
	if (exponent == this.format.specialExponent)
		if (significand != 0)
			return '';
	return this.getSign() ? '−' : '+';
};

Floatvis.prototype.getExponent = function() {
	var exponent = 0;
	var start = this.format.bits - 1;
	start -= this.format.sign;
	var end = start - this.format.exponent + 1;
	for (var i = start; i >= end; i--)
		exponent = exponent << 1 | this.getBit(i);
	return exponent;
};

Floatvis.prototype.getExponentValue = function() {
	var exponent = this.getExponent();
	if (exponent == 0 || exponent == this.format.specialExponent)
		return '';
	var adjusted = this.getExponent() - this.format.bias;
	return '2' + toSuperscript(adjusted);
};

Floatvis.prototype.getSignificand = function() {
	var significand = 0;
	var start = this.format.bits - 1;
	start -= this.format.sign + this.format.exponent;
	var end = start - this.format.significand + 1;
	for (var i = start; i >= end; i--)
		significand = significand * 2 + this.getBit(i);
	return significand;
};

Floatvis.prototype.getSignificandValue = function() {
	var significand = this.getSignificand();
	var exponent = this.getExponent();
	if (exponent == 0)
		if (significand == 0)
			return '';
	if (exponent == this.format.specialExponent) {
		if (significand == 0) {
			return '';
		} else {
			var payload = significand % this.format.quietBit;
			return '(payload: ' + payload + ')';
		}
	}
	var tempBuffer = this.buffer.slice();
	var tempNumbers = new this.format.type(tempBuffer);
	var tempOctets = new Uint8Array(tempBuffer);
	var start = this.format.bits - 1;
	var end = start - this.format.sign - this.format.exponent + 1;
	this.setBit(start - 0, 0, tempOctets);
	this.setBit(start - 1, 0, tempOctets);
	for (var i = start - 2; i >= end; i--)
		this.setBit(i, 1, tempOctets);
	var significandValue = this.getNumber(tempBuffer);
	if (exponent == 0) // subnormal number
		significandValue -= 1;
	return toSignificant(significandValue, this.format.maximumDigits);
};

Array.prototype.slice.call(
	document.querySelectorAll('.floatvis')
).forEach(function(target) {
	if (target.classList.contains('binary32'))
		new Floatvis(Floatvis.binary32, target);
	else if (target.classList.contains('binary64'))
		new Floatvis(Floatvis.binary64, target);
});

global.Floatvis = Floatvis;

function highlightOnFocus(element) {
	var select = element.select.bind(element);
	var handler = this.requestAnimationFrame.bind(this, select);
	element.addEventListener('focus', handler, false);
	element.addEventListener('click', handler, false);
}

function toSuperscript(number) {
	return number.toString().split('').map(function(digit) {
		var index = digit.charCodeAt(0) - '-'.charCodeAt(0);
		return '⁻./⁰¹²³⁴⁵⁶⁷⁸⁹'.split('')[index] || digit;
	}).join('');
}

function toSignificant(number, figures) {
	var logarithm = Math.log(Math.abs(number)) / Math.log(10);
	var digitsUnitsOrLarger = Math.floor(logarithm) + 1;
	var decimalPlaces = figures - digitsUnitsOrLarger;
	return number.toFixed(Math.max(decimalPlaces, 0));
}

})(this);
