package amirz.dngprocessor.pipeline.intermediate;

import amirz.dngprocessor.R;
import amirz.dngprocessor.gl.GLPrograms;
import amirz.dngprocessor.gl.Texture;
import amirz.dngprocessor.pipeline.Stage;
import amirz.dngprocessor.pipeline.StagePipeline;
import amirz.dngprocessor.pipeline.convert.PreProcess;
import amirz.dngprocessor.pipeline.convert.ToIntermediate;

import static android.opengl.GLES20.*;

public class SplitDetail extends Stage {
    private Texture mDetail;

    public Texture getDetail() {
        return mDetail;
    }

    @Override
    protected void execute(StagePipeline.StageMap previousStages) {
        super.execute(previousStages);
        GLPrograms converter = getConverter();

        PreProcess preProcess = previousStages.getStage(PreProcess.class);
        ToIntermediate intermediate = previousStages.getStage(ToIntermediate.class);
        BilateralFilter bilateral = previousStages.getStage(BilateralFilter.class);

        int w = preProcess.getInWidth();
        int h = preProcess.getInHeight();

        intermediate.getIntermediate().bind(GL_TEXTURE0);
        bilateral.getBilateral().bind(GL_TEXTURE2);
        converter.seti("intermediate", 0);
        converter.seti("bilateral", 2);
        mDetail = new Texture(w, h, 1, Texture.Format.Float16, null);
        mDetail.setFrameBuffer();
        converter.drawBlocks(w, h);
    }

    @Override
    public int getShader() {
        return R.raw.stage2_3_detail_fs;
    }
}
