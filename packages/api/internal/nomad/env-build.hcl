job "{{ .JobName }}/{{ .EnvID }}" {
  datacenters = ["us-central1-a"]
  type = "batch"

  priority = 20

  meta {
    # This makes sure the job always runs even though nothing has changed in the job spec file.
    # See section "Always Deploy a New Job Version" in https://storiesfromtheherd.com/nomad-tips-and-tricks-766878dfebf4
    run_uuid = "{{ .BuildID }}"
  }

  group "build" {
    reschedule {
      attempts  = 0
      unlimited = false
    }

    restart {
      attempts = 0
      mode = "fail"
    }

    task {{ .TaskName }} {
      driver = "env-build-task-driver"

      env {
        ENVS_DISK = "{{ .EnvsDisk }}"
        DOCKER_REGISTRY = "us-central1-docker.pkg.dev/e2b-prod/custom-environments"
        DOCKER_CONTEXTS_PATH = "/mnt/disks/docker-contexts/v1"
        ENVS_PIPELINE_PATH = "/mnt/disks/envs-pipeline"
        KERNEL_IMAGE_PATH = "/fc-vm/vmlinux.bin"
        FIRECRACKER_BINARY_PATH = "/usr/bin/firecracker"
      }

      config {
        BuildID = "{{ .BuildID }}"
        EnvID = "{{ .EnvID }}"
        ProvisionScript = "{{ escapeHCL .ProvisionScript }}"
        VCpuCount = "{{ .VCpuCount }}"
        DiskSizeMB = "{{ .DiskSizeMB }}"
        MemoryMB = "{{ .MemoryMB }}"
        SpanID = "{{ .SpanID }}"
        TraceID = "{{ .TraceID }}"
      }
    }
  }
}
