FROM underworldcode/underworld2_untested
MAINTAINER laikarijit@gmail.com

USER root

WORKDIR /opt
RUN git clone --depth 1 https://github.com/arijitlaik/UWGeodynamics.git
RUN pip install -e /opt/UWGeodynamics

RUN mkdir /workspace/UWGeodynamics
RUN rsync -av /opt/UWGeodynamics/examples/* /workspace/UWGeodynamics/examples/
RUN rsync -av /opt/UWGeodynamics/tutorials/* /workspace/UWGeodynamics/tutorials/
RUN rsync -av /opt/UWGeodynamics/manual/* /workspace/UWGeodynamics/manual/

# update all permissions for jovyan user
ENV NB_USER jovyan
RUN chown -R $NB_USER /workspace $UW2_DIR /home/$NB_USER

# change user and update pythonpath
USER $NB_USER
ENV PYTHONPATH $PYTHONPATH:$UW2_DIR

# move back to workspace directory
WORKDIR /workspace

# Trust underworld notebooks
RUN find -name \*.ipynb  -print0 | xargs -0 jupyter trust

# launch notebook
CMD ["jupyter", "notebook", "--ip='*'", "--no-browser"]

