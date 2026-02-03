#!/usr/bin/env bash
# apply_patch.sh — cria o módulo autobots, .gitmodules e arquivos auxiliares
# Uso: na raiz do repositório: ./apply_patch.sh
set -e

ROOT_DIR="$(pwd)"
echo "Aplicando patch de integração do L2Autobots no repositório em: $ROOT_DIR"

# 1) Atualizar settings.gradle
if grep -q "include ':autobots'" settings.gradle 2>/dev/null; then
  echo "settings.gradle já contém :autobots"
else
  echo -e "\n// ADICIONADO PELO PATCH: módulo autobots\ninclude ':autobots'\nproject(':autobots').projectDir = file('autobots')\n" >> settings.gradle
  echo "Adicionada entrada ':autobots' em settings.gradle"
fi

# 2) Criar .gitmodules para submodule vendor/L2Autobots
if [ -f .gitmodules ]; then
  echo ".gitmodules já existe; adicionando submodule se necessário"
  if ! grep -q "autobots/vendor/L2Autobots" .gitmodules; then
    cat >> .gitmodules <<'EOF'

[submodule "autobots/vendor/L2Autobots"]
	path = autobots/vendor/L2Autobots
	url = https://github.com/Elfocrash/L2Autobots.git
EOF
    echo "Adicionada entrada de submodule em .gitmodules"
  else
    echo "Submodule já registrado em .gitmodules"
  fi
else
  cat > .gitmodules <<'EOF'
[submodule "autobots/vendor/L2Autobots"]
	path = autobots/vendor/L2Autobots
	url = https://github.com/Elfocrash/L2Autobots.git
EOF
  echo "Criado .gitmodules com entrada para L2Autobots"
fi

# 3) Criar estrutura de diretórios do módulo autobots
mkdir -p autobots/src/main/kotlin/dev/l2j/autobots
mkdir -p autobots/sql
mkdir -p autobots/data

# 4) Criar build.gradle do módulo autobots
cat > autobots/build.gradle <<'EOF'
plugins {
    id 'org.jetbrains.kotlin.jvm' version '1.6.21'
    id 'java'
}

group 'net.sf.l2j'
version '1.0-SNAPSHOT'

repositories {
    mavenCentral()
    mavenLocal()
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4"
    implementation "com.fasterxml.jackson.core:jackson-databind:2.13.4"
    implementation "com.fasterxml.jackson.dataformat:jackson-dataformat-xml:2.13.4"

    # Ajuste: a sua build do Trinity pode produzir um artefato JAR com as classes net.sf.l2j.*
    # Adicione aqui a dependência para compilar contra o core do seu servidor, por exemplo:
    # compileOnly files('../L2Trinity-GF/build/libs/L2Trinity-GF.jar')
    # Ou, se o core estiver em outro projeto Gradle, altere para project(':gameserver')
    compileOnly files('../L2Trinity-GF/build/libs/L2Trinity-GF.jar')
}

sourceSets {
    main {
        kotlin {
            # Incluir o código fonte do L2Autobots que será recuperado via submodule
            srcDirs = ['src/main/kotlin', 'vendor/L2Autobots/src/main/kotlin']
        }
        resources {
            srcDirs = ['src/main/resources', 'vendor/L2Autobots/src/main/resources', 'vendor/L2Autobots/data']
        }
    }
}

tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
    kotlinOptions.jvmTarget = '1.8'
}
EOF

echo "Criado autobots/build.gradle"

# 5) Criar inicializador Kotlin (AutobotModuleInitializer)
cat > autobots/src/main/kotlin/dev/l2j/autobots/AutobotModuleInitializer.kt <<'EOF'
package dev.l2j.autobots

/**
 * AutobotModuleInitializer
 * Chamado a partir do ponto de inicialização do servidor (ex.: GameServer main, Loader, ou init hooks).
 * Este arquivo registra o AdminHandler e tenta carregar dados iniciais do módulo.
 *
 * Observação: o código do L2Autobots fica em autobots/vendor/L2Autobots (git submodule) e contém
 * as classes dev.l2j.autobots.admincommands.AdminAutobots, AutobotsManager, AutobotData, etc.
 */
object AutobotModuleInitializer {
    @JvmStatic
    fun init() {
        try {
            // Registrar handler admin (classe AdminAutobots vem do submodule)
            net.sf.l2j.gameserver.handler.AdminCommandHandler.getInstance()
                .registerHandler(dev.l2j.autobots.admincommands.AdminAutobots())
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            // Forçar inicialização das estruturas do L2Autobots (AutobotData, etc.)
            // AutobotsManager.loadAutobotDashboard() é um exemplo; ajuste conforme necessário
            dev.l2j.autobots.AutobotData // garante init do objeto
            // Chamamos um método de inicialização se existir
            try {
                val m = dev.l2j.autobots.AutobotsManager::class.java.getDeclaredMethod("loadAutobotDashboard")
                m.invoke(null)
            } catch (ignored: NoSuchMethodException) {
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
EOF
echo "Criado autobots/src/main/kotlin/dev/l2j/autobots/AutobotModuleInitializer.kt"

# 6) Criar script SQL para tabela autobots
cat > autobots/sql/create_autobots_table.sql <<'EOF'
-- create_autobots_table.sql
-- Cria tabela 'autobots' usada por L2Autobots
CREATE TABLE IF NOT EXISTS `autobots` (
  `object_id` INT NOT NULL,
  `char_name` VARCHAR(50) NOT NULL,
  `level` INT NOT NULL,
  `max_hp` INT NOT NULL,
  `current_hp` DOUBLE NOT NULL,
  `max_cp` INT NOT NULL,
  `current_cp` DOUBLE NOT NULL,
  `max_mp` INT NOT NULL,
  `current_mp` DOUBLE NOT NULL,
  `class_id` INT NOT NULL,
  `clan_id` INT DEFAULT 0,
  `activity_prefs` JSON NULL,
  `inventory` TEXT NULL,
  `appearance` TEXT NULL,
  `last_online` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`object_id`),
  UNIQUE KEY `uk_char_name` (`char_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF
echo "Criado autobots/sql/create_autobots_table.sql"

# 7) Criar README-INSTALL.md (instruções)
cat > autobots/README-INSTALL.md <<'EOF'
```markdown
# Integração L2Autobots — Instruções de instalação

Passos principais:

1. Inicializar submódulo do L2Autobots (o script já escreve .gitmodules, mas você precisa clonar o submodule):
   git submodule update --init --recursive

   Isso criará: autobots/vendor/L2Autobots

2. Ajustar dependência do core do Trinity:
   - O build do módulo autobots está configurado para compileOnly files('../L2Trinity-GF/build/libs/L2Trinity-GF.jar')
   - Se seu núcleo está em outro local ou como projeto Gradle, ajuste autobots/build.gradle:
     - use project(':gameserver') ou o caminho correto para o JAR gerado.

3. Criar tabela no banco de dados:
   - Faça backup do seu banco antes.
   - Rode:
     mysql -u <user> -p <l2db_name> < autobots/sql/create_autobots_table.sql
   - Se seu MySQL não suporta JSON, modifique a coluna activity_prefs para TEXT.

4. Build:
   - No root do repo:
     ./gradlew :autobots:build

5. Registro / inicialização em runtime:
   - Chame dev.l2j.autobots.AutobotModuleInitializer.init() durante a inicialização do servidor (no ponto onde outros handlers são registrados).
   - Exemplo: adicione a chamada no método de inicialização principal do servidor (GameServer main/Loader).

6. Uso in-game:
   - Com o módulo carregado e servidor em execução, use `//a b` conforme README do L2Autobots para abrir dashboard.

Observações:
- O código do L2Autobots é mantido em `autobots/vendor/L2Autobots` (submodule). Se quiser incorporar o código diretamente no repo (sem submodule), copie o conteúdo de `vendor/L2Autobots/src/main/kotlin` para `autobots/src/main/kotlin` e os resources para `autobots/src/main/resources`.
- Testes runtime são necessários — diferenças entre versões do Trinity e do L2Autobots podem exigir pequenas alterações de API (imports / nomes de métodos). Veja logs e ajuste classes que falharem ao compilar/rodar.
```
EOF
echo "Criado autobots/README-INSTALL.md"

echo "Patch criado. Para aplicar submodule (baixar o L2Autobots) rode:"
echo "  git submodule update --init --recursive"
echo "Depois, para compilar: ./gradlew :autobots:build"

echo "Concluído."