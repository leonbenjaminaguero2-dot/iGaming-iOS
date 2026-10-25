# iGaming para iOS

App nativa SwiftUI con mando Bluetooth, biblioteca vacía e icono aprobado. Sin juegos precargados, Steam, Epic ni emulación.

## GitHub Actions

Subí el contenido de esta carpeta a la raíz del repo y ejecutá Actions: Build iGaming for iOS. El workflow siempre crea iGaming-Simulator.zip. Si encuentra secretos de firma válidos, también crea iGaming-IPA.

Para firmar IPA, configura IOS_CERTIFICATE_P12_BASE64, IOS_CERTIFICATE_PASSWORD, IOS_PROVISIONING_PROFILE_BASE64 e IOS_TEAM_ID en GitHub Actions Secrets; configura IOS_BUNDLE_ID como variable con el Bundle ID que coincide con el perfil. El perfil de desarrollo debe incluir el iPhone.

Las tarjetas abren el servicio oficial. La biblioteca no muestra juegos hasta integrar catálogos autorizados. El lanzamiento directo de cada título requiere catálogo y enlaces oficiales por proveedor; la app no emula ni transmite por sí misma.
