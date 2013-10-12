mergeInto(LibraryManager.library, {
	
	OgvJsInitVideo: function(frameWidth, frameHeight,
                             fps,
                             picWidth, picHeight,
                             picX, picY) {
		OgvJsInitVideoCallback({
			codec: "Theora",
			frameWidth: frameWidth,
			frameHeight: frameHeight,
			fps: fps,
			picWidth: picWidth,
			picHeight: picHeight,
			picX: picX,
			picY: picY
		});
	},

	OgvJsOutputFrame: function(bufferY, strideY,
	                           bufferCb, strideCb,
	                           bufferCr, strideCr,
	                           width, height,
	                           hdec, vdec) {
		// YCbCr whee
		var HEAPU8 = Module.HEAPU8;
		var imageData = OgvJsImageData(width, height);
		var data = imageData.data;
		var YPtr, CbPtr, CrPtr, outPtr;
		var xdec, ydec;
		var colorY, colorCb, colorCr;
		var multY;
		for (var y = 0; y < height; y++) {
			ydec = y >> vdec;
			YPtr = bufferY + y * strideY;
			CbPtr = bufferCb + ydec * strideCb;
			CrPtr = bufferCr + ydec * strideCr;
			outPtr = y * 4 * width;
			for (var x = 0; x < width; x++) {
				xdec = x >> hdec;
				colorY = HEAPU8[YPtr + x];
				colorCb = HEAPU8[CbPtr + xdec];
				colorCr = HEAPU8[CrPtr + xdec];
				
				// Quickie YUV conversion
				// https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.2020_conversion
				multY = (298.082 * colorY) / 256;
				data[outPtr++] = multY + (408.583 * colorCr) / 256 - 222.921;
				data[outPtr++] = multY - (100.291 * colorCb) / 256 - (208.120 * colorCr) / 256 + 135.576;
				data[outPtr++] = multY + (516.412 * colorCb) / 256 - 276.836;
				data[outPtr++] = 255;
			}
		}
		OgvJsFrameCallback(imageData);
	},
	
	OgvJsInitAudio: function(channels, rate) {
		OgvJsInitAudioCallback({
			codec: "Vorbis",
			channels: channels,
			rate: rate
		});
	},
	
	OgvJsAudioCallback: function(buffer, bufSize) {
		var HEAPU8 = Module.HEAPU8;
		var data = new ArrayBuffer(bufSize);
		// fixme copy more efficiently than this
		var outBytes = new UIntArray(data);
		for (var i = 0; i < bufSize; i++) {
			outBytes[i] = HEAPU8[buffer + i];
		}
		OgvJsAudioCallback(data);
	}

});
