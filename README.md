# apple-container-tramp - TRAMP integration for Apple container

## Usage

Offers the TRAMP method `container` to access running containers

```
C-x C-f /container:user@container:/path/to/file

where
  user           is the user that you want to use inside the container (optional)
  container-id   is the id or name of the container
```

### Multi-hop examples

If you container is hosted on `vm.example.net`:

```
/ssh:vm-user@vm.example.net|container:user@container:/path/to/file
```

If you need to run the `container` command as, say, the `root` user:

```
/sudo:root@localhost|container:user@container:/path/to/file
```
