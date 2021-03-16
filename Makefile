##################################
#
# Create multi-platform docker image. If you have native systems around, using
# them will be much more efficient at build time. See e.g.
# https://netfuture.ch/2020/05/multi-arch-docker-image-easy/

# Tag without version
BASETAG     = trifence/hiddenservice

# For version x.y.z, output "-t …:x.y -t …:x.y.z";
# for anything else, output nothing
VERSIONTAGS = $(shell echo ${VERSION} | sed -n -e 's,^VERSION=\(\([0-9]*.[0-9]*\).[0-9]*\)$$,-t ${BASETAG}:\1 -t ${BASETAG}:\2,p' VERSION)

# debian:buster-slim also supports
# linux/i386,linux/arm64/v8,linux/mips64le,linux/ppc64le,linux/s390x.
# Not using i386 as it has compile problems (build for x86-64 by default in the
# i386 container); probably not used anymore anyway.
PLATFORMS  = linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6

# Where buildx probably lives (ugly, sorry)
BUILDXDETECT = ${HOME}/.docker/cli-plugins/docker-buildx

# Just one of the many files created
QEMUDETECT = /proc/sys/fs/binfmt_misc/qemu-m68k

docker-multiarch: qemu buildx docker-multiarch-builder
	docker buildx build --builder docker-multiarch --pull --load \
		--build-arg VERSIONMATCH=${VERSIONMATCH} \
		--platform ${PLATFORMS} ${VERSIONTAGS} \
		-t ${BASETAG}:latest .

docker-multiarch-push: docker-multiarch
	docker push ${VERSIONTAGS} -t ${BASETAG}:latest

.PHONY: qemu buildx docker-multiarch-builder docker-multiarch docker-multiarch-push

qemu:	${QEMUDETECT}
${QEMUDETECT}:
	docker pull multiarch/qemu-user-static
	docker run --privileged multiarch/qemu-user-static --reset -p yes
	docker ps -a | sed -n 's, *multiarch/qemu-user-static.*,,p' \
	  | (xargs docker rm 2>&1 || \
	    echo "Cannot remove docker container on ZFS; retry after next reboot") \
	  | grep -v 'dataset is busy'

buildx: ${BUILDXDETECT}
${BUILDXDETECT}:
	@echo
# Output of `uname -m` is too different 
	@echo '*** `docker buildx` missing. Install binary for this machine architecture'
	@echo '*** from `https://github.com/docker/buildx/releases/latest`'
	@echo '*** to `~/.docker/cli-plugins/docker-buildx` and `chmod +x` it.'
	@echo
	@exit 1

docker-multiarch-builder: qemu buildx
	if ! docker buildx ls | grep -w docker-multiarch > /dev/null; then \
		docker buildx create --name docker-multiarch && \
		docker buildx inspect --builder docker-multiarch --bootstrap; \
	fi
