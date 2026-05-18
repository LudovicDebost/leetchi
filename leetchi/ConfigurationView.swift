import SwiftUI
import WidgetKit

struct ConfigurationView: View {
    @AppStorage(TCLConfiguration.keyGrandLyonBaseURL, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var grandLyonBaseURL = TCLConfiguration.default.grandLyonBaseURL

    @AppStorage(TCLConfiguration.keyLines, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var lines = TCLConfiguration.default.lines

    @AppStorage(TCLConfiguration.keyStops, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var stops = TCLConfiguration.default.stops

    @AppStorage(TCLConfiguration.keyDirections, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var directions = TCLConfiguration.default.directions

    @AppStorage(TCLConfiguration.keyUsername, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var username = TCLConfiguration.default.username

    @AppStorage(TCLConfiguration.keyPassword, store: UserDefaults(suiteName: TCLConfiguration.appGroupID))
    private var password = TCLConfiguration.default.password

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("API Grand Lyon") {
                    TextField("URL base datapusher", text: $grandLyonBaseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    TextField("Utilisateur (optionnel)", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Mot de passe (optionnel)", text: $password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    TextField("Lignes (ex. C26,70)", text: $lines)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)

                    TextField("IDs d'arrêts (ex. 2294,42561)", text: $stops)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()

                    TextField("Directions (optionnel, IDs d'arrêts)", text: $directions)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                } header: {
                    Text("Lignes & Arrêts TCL")
                } footer: {
                    Text("Les IDs d'arrêts sont disponibles sur le portail data.grandlyon.com. Un ID correspond à une direction : prenez l'ID de chaque quai pour afficher les deux sens.")
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") {
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                }
            }
        }
    }
}
