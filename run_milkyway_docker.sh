sudo docker run -d --net=host -v galaxy_storage:/export/ \
	-e "GALAXY_CONFIG_ADMIN_USERS=admin@galaxy.org" \
	-e "GALAXY_CONFIG_MASTER_API_KEY=37430b18a3e4610ea243c316b293d06f" \
	-e "GALAXY_CONFIG_REQUIRE_LOGIN='True'" \
	-e "GALAXY_CONFIG_HOST='0.0.0.0'" \
        -e "NONUSE=slurmd,slurmctld" \
        -e "GALAXY_DESTINATIONS_DEFAULT=local" \
        -e "GALAXY_LOGGING=full" \
        -e "GALAXY_DOCKER_ENABLED=True" \
        --privileged=true \
	wbarshop/milkyway_galaxy
