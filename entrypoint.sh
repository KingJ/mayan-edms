#!/bin/bash
set -e

initialize() {
    mayan-edms.py initialsetup
    cat /local.py >> $MAYAN_INSTALL_DIR/settings/local.py
    chown -R www-data:www-data $MAYAN_INSTALL_DIR
}

upgrade() {
    mayan-edms.py performupgrade
}

start() {
    rm -rf /var/run/supervisor.sock
    exec /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf
}

restart() {
    supervisorctl restart all
}

restore_base_settings() {
    # Restore a backup copy of the base settings files in case host directories
    # are used for volumes.
    # Issue: https://gitlab.com/mayan-edms/mayan-edms-docker/issues/6
    #
    # Cause: "Volumes are initialized when a container is created. If the
    # container’s base image contains data at the specified mount point, that
    # existing data is copied into the new volume upon volume initialization.
    # (Note that this does not apply when mounting a host directory.)"
    #
    # https://docs.docker.com/engine/tutorials/dockervolumes/

    cp $MAYAN_INSTALL_DIR/settings-backup/*.py  $MAYAN_INSTALL_DIR/settings/
}

restore_media_directory() {
    # Restore a backup copy of the media directory in case host directories
    # are used for volumes.
    # Issue: https://gitlab.com/mayan-edms/mayan-edms-docker/issues/6
    #
    # Cause: "Volumes are initialized when a container is created. If the
    # container’s base image contains data at the specified mount point, that
    # existing data is copied into the new volume upon volume initialization.
    # (Note that this does not apply when mounting a host directory.)"
    #
    # https://docs.docker.com/engine/tutorials/dockervolumes/

    cp $MAYAN_INSTALL_DIR/media-backup/*  $MAYAN_INSTALL_DIR/media/ -ax
}

case ${1} in
  mayan:start)
    start
    ;;
  mayan:init)
    restore_base_settings
    restore_media_directory
    initialize
    ;;
  mayan:upgrade)
    upgrade
    ;;
  mayan:restart)
    restart
    ;;
  mayan:help)
    echo "Available options:"
    echo " app:start        - Starts the server (default)"
    echo " app:init         - Initialize the installation (e.g. create databases, migrate database)."
    echo " app:upgrade      - Migrate an existing database to a current version."
    echo " app:help         - Displays the help"
    echo " [command]        - Execute the specified command, eg. bash."
    ;;
  *)
    exec "$@"
    ;;
esac
