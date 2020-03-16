package amirz.dngprocessor.device;

import android.util.SparseArray;

import amirz.dngprocessor.params.SensorParams;
import amirz.dngprocessor.parser.TIFF;
import amirz.dngprocessor.parser.TIFFTag;

class OnePlus extends Generic {
    @Override
    public boolean isModel(String model) {
        return model.startsWith("ONEPLUS");
    }

    void matrixCorrection(SparseArray<TIFFTag> tags, SensorParams sensor) {
        TIFFTag software = tags.get(TIFF.TAG_Software);
        if (software != null && software.toString().startsWith("OnePlus")) {
            // Credits to Savitar for these values
            sensor.colorMatrix1 = new float[] {
                    1.0612f, -0.4169f, -0.1001f,
                    -0.3982f, 1.2675f, 0.1412f,
                    -0.0558f, 0.162f, 0.5206f
            };

            sensor.colorMatrix2 = new float[] {
                    1.2341f, -0.666f, 0.0994f,
                    -0.2806f, 1.0683f, 0.2451f,
                    0.0127f, 0.0727f, 0.5789f
            };

            sensor.forwardTransform1 = new float[] {
                    0.4226f, 0.4079f, 0.1337f,
                    0.1871f, 0.7745f, 0.0384f,
                    0.0618f, 0.0047f, 0.7586f
            };

            sensor.forwardTransform2 = new float[] {
                    0.4187f, 0.4351f, 0.1105f,
                    0.1772f, 0.7902f, 0.0326f,
                    0.047f, 0.001f, 0.7772f
            };
        }
    }

    @Override
    void saturationCorrection(float[] saturationMap) {
        super.saturationCorrection(saturationMap);
        saturationMap[0] *= 1.3f;
        saturationMap[1] *= 1.25f;
        saturationMap[2] *= 1.5f;
        saturationMap[3] *= 1.6f;
        saturationMap[4] *= 1.55f;
        saturationMap[5] *= 1.5f;
        saturationMap[6] *= 1.45f;
        saturationMap[7] *= 1.25f;
    }
}
