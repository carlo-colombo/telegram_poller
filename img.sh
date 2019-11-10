docker run --rm -it \
   --name img \
   --volume "$(pwd):/home/user/src:ro" \
   --workdir /home/user/src \
   --volume "${HOME}/.docker:/root/.docker:ro" \
   --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
   r.j3ss.co/img build -f Dockerfile.min  --label alpine=1.8.0 -t telegram-poller-img .
