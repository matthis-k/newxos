FROM ghcr.io/matatonic/openedai-speech:latest

# PyTorch wheels in the upstream image do not support RTX 5060 / Blackwell sm_120.
RUN pip install --no-cache-dir --upgrade \
    torch==2.11.0+cu128 \
    torchaudio==2.11.0+cu128 \
    --index-url https://download.pytorch.org/whl/cu128

RUN pip install --no-cache-dir torchcodec==0.13.0
