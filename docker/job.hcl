job "pulfalight" {
  region = "global"
  datacenters = ["dc1"]
  type = "service"
  group "rdbms" {
    count = 1
    network {
      port "postgres" { to = 5432 }
    }
    service {
      port = "postgres"
      check {
        name = "postgres_probe"
        type = "tcp"
        interval = "10s"
        timeout = "1s"
      }
    }
    task "postgres" {
      driver = "podman"
      config {
        image = "docker.io/library/postgres:15.5-bullseye"
        ports = ["postgres"]
      }
      template { 
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- with nomadVar "nomad/jobs/pulfalight" -}}
        POSTGRES_PASSWORD = {{ .DB_PASSWORD }}
        POSTGRES_USER = {{ .DB_USERNAME }}
        POSTGRES_DB = {{ .DB }}
        {{- end -}}
        EOF
      }
    }
  }
  group "solr" {
    count = 1
    network {
      port "solr" {
        static = 9000
        to = 8983
      }
    }
    service {
      port = "solr"
      check {
        type = "tcp"
        port = "solr"
        interval = "10s"
        timeout  = "1s"
      }
    }
    task "solrcloud" {
      driver = "podman"
      config {
        image = "docker.io/library/solr:8.4"
        command = "bash"
        /* args = ["-c", "mkdir /tmp/pulfalight && precreate-core gettingstarted && solr-foreground"] */
        /* command = "bash" */
        args    = ["-c", "mkdir /tmp/pulfalight && wget -O /tmp/pulfalight/schema.xml \"https://raw.githubusercontent.com/pulibrary/pulfalight/main/solr/conf/schema.xml\" && wget -O /tmp/pulfalight/solrconfig.xml \"https://raw.githubusercontent.com/pulibrary/pulfalight/main/solr/conf/solrconfig.xml\" && wget -O /tmp/pulfalight/synonyms.txt \"https://raw.githubusercontent.com/pulibrary/pulfalight/main/solr/conf/synonyms.txt\" && wget -O /tmp/pulfalight/stopwords.txt \"https://raw.githubusercontent.com/pulibrary/pulfalight/main/solr/conf/stopwords.txt\" && wget -O /tmp/pulfalight/protwords.txt \"https://raw.githubusercontent.com/pulibrary/pulfalight/main/solr/conf/protwords.txt\" && solr-precreate pulfalight /tmp/pulfalight"]
        ports = ["solr"]
      }
    }
  }
  group "web" {
    count = 1
    network {
      port "http" { to = 8000 }
    }
    service {
      port = "http"
      check {
        type = "http"
        port = "http"
        path = "/"
        interval = "10s"
        timeout = "1s"
      }
    }
    task "dbmigrate" {
      # The dbmigrate task will run BEFORE the puma task in this group.
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "podman"
      config {
        image = "ghcr.io/pulibrary/pulfalight:pr-1367"
        command = "bash"
        args    = ["-c", "bundle exec rake db:migrate"]
        auth {
          username = "${GITHUB_CONTAINER_REGISTRY_USERNAME}"
          password = "${GITHUB_CONTAINER_REGISTRY_PASSWORD}"
        }
      }
      template {
        destination = "secrets/secret.env"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- with nomadVar "nomad/jobs" -}}
        GITHUB_CONTAINER_REGISTRY_USERNAME = {{ .GITHUB_CONTAINER_REGISTRY_USERNAME }}
        GITHUB_CONTAINER_REGISTRY_PASSWORD = {{ .GITHUB_CONTAINER_REGISTRY_PASSWORD }}
        {{- end -}}
        EOF
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- range service "pulfalight-rdbms" }}
        PULFALIGHT_DB_HOST={{ .Address }}
        lando_pulfalight_database_conn_port={{ .Port }}
        {{ end }}
        {{- with nomadVar "nomad/jobs/pulfalight" -}}
        PULFALIGHT_DB_USERNAME = {{ .DB_USERNAME }}
        PULFALIGHT_DB_PASSWORD = {{ .DB_PASSWORD }}
        SOLR_URL=http://solr:8983/solr/core
        SECRET_KEY_BASE=1
        RAILS_SERVE_STATIC_FILES=true
        RAILS_LOG_TO_STDOUT=true
        APPLICATION_PORT=8000
        PULFALIGHT_DB= {{ .DB }}
        {{- end -}}
        EOF
      }
    }
    task "rails" {
      driver = "podman"
      config {
        image = "ghcr.io/pulibrary/pulfalight:pr-1367"
        ports = ["http"]
        auth {
          username = "${GITHUB_CONTAINER_REGISTRY_USERNAME}"
          password = "${GITHUB_CONTAINER_REGISTRY_PASSWORD}"
        }
      }
      template {
        destination = "secrets/secret.env"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- with nomadVar "nomad/jobs" -}}
        GITHUB_CONTAINER_REGISTRY_USERNAME = {{ .GITHUB_CONTAINER_REGISTRY_USERNAME }}
        GITHUB_CONTAINER_REGISTRY_PASSWORD = {{ .GITHUB_CONTAINER_REGISTRY_PASSWORD }}
        {{- end -}}
        EOF
      }
      template { 
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env = true
        change_mode = "restart"
        data = <<EOF
        {{- range service "pulfalight-rdbms" }}
        PULFALIGHT_DB_HOST={{ .Address }}
        lando_pulfalight_database_conn_port={{ .Port }}
        {{ end }}
        {{- range service "pulfalight-solr" }}
        SOLR_URL=http://{{ .Address }}:{{ .Port }}/solr/pulfalight
        {{ end }}
        {{- with nomadVar "nomad/jobs/pulfalight" -}}
        PULFALIGHT_DB_USERNAME = {{ .DB_USERNAME }}
        PULFALIGHT_DB_PASSWORD = {{ .DB_PASSWORD }}
        SECRET_KEY_BASE=1
        RAILS_SERVE_STATIC_FILES=true
        APPLICATION_PORT=8000
        PULFALIGHT_DB= {{ .DB }}
        {{- end -}}
        EOF
      }
    }
  }
}
