package {
    import flash.display.Sprite;
    import flash.events.SampleDataEvent;
    import flash.external.ExternalInterface;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    
    public class dynamicaudio extends Sprite {
        public var bufferSize:Number = 2048; // In samples
        public var sound:Sound = null;
        public var soundChannel:SoundChannel = null;
        public var buffer:Array = [];
        public var fudgeFactor:Number = 0;
        public var hexValues:Array = [];
        
        public function dynamicaudio() {
            ExternalInterface.addCallback('write',  write);
            ExternalInterface.addCallback('playbackPosition', playbackPosition);
            ExternalInterface.addCallback('samplesQueued', samplesQueued);
            
            // Create a hex digit lookup table
            var hexDigits:Array = ['0', '1', '2', '3', '4', '5', '6', '7',
                                   '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
            for (var i = 0; i < hexDigits.length; i++) {
            	this.hexValues[hexDigits[i].charCodeAt(0)] = i;
            }
        }
        
        // Called from JavaScript to add samples to the buffer
        // Note we are using a space separated string of samples instead of an 
        // array. Flash's stupid ExternalInterface passes every sample as XML, 
        // which is incredibly expensive to encode/decode
        public function write(s:String):void {
            if (!this.sound) {
                this.sound = new Sound(); 
                this.sound.addEventListener(
                    SampleDataEvent.SAMPLE_DATA,
                    soundGenerator
                );
                this.soundChannel = this.sound.play();
            }
            
            var multiplier:Number = 1/32768;
            /*
            for each (var sample:String in s.split(" ")) {
                this.buffer.push(parseInt(sample, 10)*multiplier);
            }
            */
            var hexValues:Array = this.hexValues;
            for (var i = 0; i < s.length; i += 4) {
            	var sample:Number = (hexValues[s.charCodeAt(i)]) +
            	                    (hexValues[s.charCodeAt(i + 1)] << 4) +
            	                    (hexValues[s.charCodeAt(i + 2)] << 8) +
            	                    (hexValues[s.charCodeAt(i + 3)] << 12);
            	if (sample & 0x8000) {
            		// sign extension from 16 to 32-bit int!
            		sample = sample - 0x10000;
            	}
            	this.buffer.push(sample * multiplier);
            }
        }

        public function samplesQueued():Number {
        	return this.buffer.length / 2;
        }
        
        public function playbackPosition():Number {
        	if (this.soundChannel == null) {
        		return 0;
        	} else {
        		return this.soundChannel.position / 1000 - this.fudgeFactor;
        	}
        }

        public function soundGenerator(event:SampleDataEvent):void {
            var i:int;
            
            // If we haven't got enough data, write 2048 samples of silence to 
            // both channels, the minimum Flash allows
            if (this.buffer.length < this.bufferSize*2) {
                for (i = 0; i < 4096; i++) {
                    event.data.writeFloat(0.0);
                }
                this.fudgeFactor += (2048 / 44100);
                return;
            }
            
            var count:Number = Math.min(this.buffer.length, 16384);
            
            for each (var sample:Number in this.buffer.slice(0, count)) {
                event.data.writeFloat(sample);
            }
            
            this.buffer = this.buffer.slice(count, this.buffer.length);
        }
    }
}

