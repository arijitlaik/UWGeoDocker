FROM underworldcode/base@sha256:59e242b34ea610784838232b93b81799828a3c59a25946e01129b71aae26ee3d
MAINTAINER https://github.com/underworldcode/

# set working directory to /opt, and install underworld files there.
WORKDIR /opt
ENV UW2_DIR /opt/underworld2
RUN mkdir $UW2_DIR
ENV PYTHONPATH $PYTHONPATH:$UW2_DIR
ENV NB_WORK /workspace

# add default user jovyan and change permissions on NB_WORK
ENV NB_USER jovyan
RUN useradd -m -s /bin/bash -N jovyan

# copy this file over so that no password is required
COPY docs/development/docker/underworld2_untested/jupyter_notebook_config.json /home/$NB_USER/.jupyter/jupyter_notebook_config.json

# install lavavu
RUN git clone https://github.com/OKaluza/LavaVu && \
    cd LavaVu
    make -j4
ENV PYTHONPATH $PYTHONPATH:/opt/LavaVu

# COPY UW
#COPY --chown=jovyan:users . $UW2_DIR/   # unfortunately, the version of docker at docker cloud does not support chown yet.
COPY . $UW2_DIR/

# get underworld, compile, delete some unnecessary files, trust notebooks, copy to workspace
RUN cd underworld2/libUnderworld && \
    ./configure.py --with-debugging=0  && \
    ./compile.py                 && \
    rm -fr h5py_ext              && \
    rm .sconsign.dblite          && \
    rm -fr .sconf_temp           && \
    cd build                     && \
    rm -fr libUnderworldPy       && \
    rm -fr StGermain             && \
    rm -fr gLucifer              && \
    rm -fr Underworld            && \
    rm -fr StgFEM                && \
    rm -fr StgDomain             && \
    rm -fr PICellerator          && \
    rm -fr Solvers               && \
    find $UW2_DIR/docs -name \*.ipynb  -print0 | xargs -0 jupyter trust && \
    cd ../../docs/development/api_doc_generator/                     && \
    sphinx-build . ../../api_doc                                     && \
    mkdir $NB_WORK                                                   && \
    rsync -av $UW2_DIR/docs/. $NB_WORK                               && \
    cd /opt/underworld2                                              && \
    find . -name \*.os |xargs rm -f                                  && \
    cat .git/refs/heads/* > build_commit.txt                         && \
    env > build_environment.txt                                      && \
    rm -fr .git                                                      && \
    chown -R $NB_USER:users $NB_WORK $UW2_DIR /home/$NB_USER


# kiwisolver hack, and pipe down numpy warnings
RUN sed -i "1i import kiwisolver as _ks;import warnings as _warnings;_warnings.filterwarnings(\"ignore\")" /opt/underworld2/underworld/__init__.py

# expose notebook port
EXPOSE 8888
# expose glucifer port
EXPOSE 9999

# CHANGE USER
USER $NB_USER
ENV PYTHONPATH $PYTHONPATH:$UW2_DIR

# setup symlink for terminal convenience
RUN ln -s $NB_WORK /home/$NB_USER/

# create a volume
VOLUME $NB_WORK/user_data
WORKDIR $NB_WORK

# launch notebook
CMD ["jupyter", "notebook", "--ip='*'", "--no-browser"]


USER root

RUN apt-get update -qq
RUN DEBIAN_FRONTEND=noninteractive apt-get install cgdb sudo htop nano tmux openssh-client ne

# UWGeodynamics
WORKDIR /opt
RUN git clone -b development https://github.com/arijitlaik/UWGeodynamics.git
RUN pip install -e /opt/UWGeodynamics
RUN mkdir /workspace/UWGeodynamics
RUN mkdir /workspace/MODELS_RESULTS
RUN rsync -av /opt/UWGeodynamics/examples/* /workspace/UWGeodynamics/examples/
RUN rsync -av /opt/UWGeodynamics/tutorials/* /workspace/UWGeodynamics/tutorials/
RUN rsync -av /opt/UWGeodynamics/manual/* /workspace/UWGeodynamics/manual/

# # Badlands dependency
# RUN pip install pandas
# RUN pip install ez_setup
# RUN pip install git+https://github.com/badlands-model/triangle.git
# RUN pip install git+https://github.com/awickert/gFlex.git

# # pyBadlands serial
# WORKDIR /opt
# RUN git clone https://github.com/rbeucher/pyBadlands_serial.git
# RUN pip install -e pyBadlands_serial/
# WORKDIR /opt/pyBadlands_serial/pyBadlands/libUtils
# RUN make
# RUN pip install -e /opt/pyBadlands_serial

# # pyBadlands dependencies
# RUN pip install cmocean
# RUN pip install colorlover
# # Force matplotlib 2.1.2 (Bug Badlands), Temporary
# RUN pip install matplotlib==2.1.2

# pyBadlands companion
# WORKDIR /opt
# RUN git clone https://github.com/badlands-model/pyBadlands-Companion.git
# RUN pip install -e /opt/pyBadlands-Companion
# RUN mkdir /workspace/BADLANDS
# RUN rsync -av /opt/pyBadlands-Companion/notebooks/* /workspace/BADLANDS/companion/

# ENV PATH $PATH:/opt/pyBadlands_serial/pyBadlands/libUtils
# ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/pyBadlands_serial/pyBadlands/libUtils

# memory profiler and jupyterlab
RUN pip install memory_profiler
RUN pip install jupyterlab
RUN jupyter serverextension enable --py jupyterlab --sys-prefix

# update all permissions for jovyan user
ENV UW2_DIR /opt/underworld2
#RUN useradd -m -s /bin/bash -N jovyan
RUN echo "jovyan:docker" | chpasswd && adduser jovyan sudo
ENV NB_USER jovyan

# copy this file over so that no password is required
COPY jupyter_notebook_config.json /home/$NB_USER/.jupyter/jupyter_notebook_config.json

# update all permissions for user
RUN chown -R $NB_USER:users /workspace $UW2_DIR /home/$NB_USER /opt/pyBadlands_serial

# change user and update pythonpath
USER $NB_USER
ENV PYTHONPATH $PYTHONPATH:$UW2_DIR
ENV PYTHONPATH /workspace/user_data/UWGeodynamics:$PYTHONPATH

# move back to workspace directory
WORKDIR /workspace

# launch notebook
CMD ["jupyter", "lab", "--ip='*'", "--no-browser"]

