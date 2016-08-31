namespace Yenc;

class yEnc
{
	public decoded;

	public encoded;

	/**
	 * Filename to use for encoding or decoding.
	 */
	protected filename {
		get, set, toString
	};

	/*
	 * Text of the most recent error message (if any).
	 */
	public lastError;

	public function decode(string! encodedText) -> string|boolean
	{
		var dummy, entry;
		array text = [], matches = [];
		int arraySize, code, index = 0, lineSize, headSize, tailSize;
		string crc, decoded = "", message = "", head, line, tail;

		let this->decoded = "";
		let this->filename = "";
		let this->lastError = "";
		let this->encoded = encodedText;

		let text = (array)explode("\r\n", trim(encodedText));

		let arraySize = count(text);
		if unlikely (arraySize < 3) {
			let this->lastError = "Data too short. There should be at least three lines.";
			return false;
		}

		let head = (string)array_shift(text);
		if preg_match(
			"#^=ybegin\s+line=(?P<line>\d+)\s+size=(?P<size>\d+)\s+name=(?P<name>[^ ]+)#i",
//" corrects colouring of strings in PHPS.
			head,
			matches
		) {
			let headSize = (int)matches["size"];
			let lineSize = (int)matches["line"];
			let this->filename = (string)matches["name"];
		} else {
			let this->lastError = "Failed to match head" . PHP_EOL . head;
			return false;
		}

		let tail = (string)array_pop(text);

		if preg_match(
			"#^=yend\s+size=(?P<size>\d+)\s+crc32=(?P<crc>[a-f0-9]+)#i",
			tail,
			matches
		) {
			let tailSize = (int)matches["size"];
			let crc = (string)matches["crc"];
		} else {
			let this->lastError = "Failed to match tail" . PHP_EOL . tail;
			return false;
		}

		// Make sure the prefix and suffix filesizes match up.
		if unlikely headSize != tailSize {
			let dummy = headSize;
			let message = "Header/trailer file sizes do not match (" . (string)dummy . "/";
			let dummy = tailSize;
			let message .= (string)dummy . "). This is a violation of the yEnc specification and indicates probable corruption.";
			let this->lastError = message;

			return false;
		}

		for entry in text {
			let index = 0;
			let line = (string)entry;
			let lineSize = line->length();
			if unlikely lineSize == 0 {
				continue;
			}

			// Decode loop
			while index < lineSize {
				let dummy = line[index];
				let index++;
				let code = (int)dummy;
				if code == 61 { // '='
					if unlikely (lineSize <= index) {
						let this->lastError = "Last character of a line cannot be the escape character. The file is probably corrupt."
							 . PHP_EOL;
						this->echoAsHex(line);	// debug
						return false;
					} else {
						let dummy = line[index];
						let index++;
						let code = ((int)dummy - 64);
						if code < 0 {
							let code += 256;
						}
					}
				}

				let code = (code - 42);
				if code < 0 {
					let code += 256;
				}

				//let dummy = chr(code);
				let decoded .= chr(code);
			}
		}
		let this->decoded = decoded;

		// Make sure the decoded filesize is the same as the size specified in the header.
		let tailSize = decoded->length();
		if tailSize != headSize {
			let dummy = headSize;
			let message = "Header file size (" . (string)dummy . ") and actual file size (";
			let dummy = tailSize;
			let message .= (string)dummy . ") do not match. The file is probably corrupt.";
			let this->lastError = message;

			return false;
		}

		// Check the CRC value
		let dummy = sprintf("%X", crc32(this->decoded));
		if !empty crc && (crc->upper() != (string)dummy) {
			let this->lastError = "CRC32 checksums do not match (" . crc->upper() . "/" . (string)dummy . "). The file is probably corrupt.";

			return false;
		}

		return decoded;
	}

	public function encode(string! fileData, string! fileName, int! maxLineLen = 128) -> string|boolean
	{
		var dummy;
		array output = [];
		int charCount, code, index = 0;
		string encoded;

		let this->filename = fileName;
		let this->lastError = "";

		if (fileData->length() < 1) {
			throw new \UnexpectedValueException("There must be some content to encode.");
		}

		if (fileName->length() == 0) {
			throw new \UnexpectedValueException("Filename is required.");
		}

		if (maxLineLen < 1 || maxLineLen > 254) {
			throw new \RangeException("The maximum line length must be between 1 and 254 inclusive.");
		}

		let output[0] = (string)sprintf(
			"=ybegin line=%s size=%s name=%s",
			maxLineLen,
			fileData->length(),
			fileName
		);

		let charCount = maxLineLen;
		while index < fileData->length() {
			let dummy = fileData[index];
			let index++;
			let code = ((int)dummy + 42) % 256;

			switch (code) {
				case 0x00:	// null
				case 0x09:	// HT
				case 0x0A:	// LF
				case 0x0D:	// CR
				case 0x20:	// space
				case 0x3D:  // Including the escape character itself
					let encoded .= '=';	// Escape the the next character.
					let charCount--;
					let code = (code + 64) % 256;
					break;
// First or last column only.
//						break;
//				case 0x2E:  // Some unusual servers have problems with a full-stop in the first column
//						break;
				default:
					break;
			}

			let encoded .= chr(code);
			let charCount--;

			if charCount < 1 {
				let output[] = encoded;
				let encoded = "";
				let charCount = maxLineLen;
			}
		}
		let output[] = encoded;

		let output[] = (string)sprintf("=yend size=%d crc32=%x", fileData->length(), crc32(fileData));

		return implode("\r\n", output);
	}

	protected function createTestString() -> string
	{
		//var dummy;
		string data = "";
		int ch;

		for ch in range(0, 255) {
			let data .= chr(ch);
			//echo ch, PHP_EOL;
		}

		return data;
	}

	protected function echoAsHex(string! line) {
		char ascii;
		var dummy;

		for ascii in line {
			echo ascii->toHex();
			echo ",";
		}
		let dummy = chr(8);
		echo (string)dummy . " " . PHP_EOL;
	}
}
