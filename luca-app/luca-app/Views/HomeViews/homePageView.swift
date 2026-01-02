import SwiftUI


struct HomePageView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        MainTabView(isAuthenticated: $isAuthenticated)
    }
}
// Preview
#Preview {
    HomePageView(isAuthenticated: .constant(true))
}

struct HomeTab: View {
    @Binding var isAuthenticated: Bool
    @State private var userName = ""
    @State private var isLoadingUser = true
    @State private var newsItems: [NewsItem] = []
    @State private var displayedNewsCount = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Welcome Section
                        VStack(alignment: .leading, spacing: 4) {
                            if isLoadingUser {
                                Text("Welcome!")
                                    .font(.system(size: 28, weight: .bold))
                            } else {
                                Text("Welcome, \(userName)")
                                    .font(.system(size: 28, weight: .bold))
                            }
                            
                            Text("Continue your nursing excellence journey")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 80)
                        .padding(.bottom, 20)
                        
                        // Latest News Header
                        HStack {
                            Image(systemName: "newspaper")
                                .foregroundStyle(Color(hex: "D9B53E"))
                            
                            Text("Latest News")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button {
                                loadMoreNews()
                            } label: {
                                Text("Show More")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "D9B53E"))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        // News Cards
                        VStack(spacing: 12) {
                            ForEach(Array(newsItems.prefix(displayedNewsCount).enumerated()), id: \.element.id) { index, item in
                                NewsCard(
                                    imageName: item.imageName,
                                    category: item.category,
                                    categoryColor: item.categoryColor,
                                    timeAgo: item.timeAgo,
                                    title: item.title,
                                    description: item.description,
                                    readTime: item.readTime,
                                    views: item.views
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                        if displayedNewsCount > 3 {
                            Button {
                                collapseNews()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.up")
                                    Text("Show Less")
                                    Image(systemName: "chevron.up")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "D9B53E"))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
                .background(Color(hex: "F5E8C7"))
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationBarHidden(true)
            .onAppear {
                loadUserProfile()
                loadInitialNews()
            }
        }
    }
    
    // Load user profile from API
    private func loadUserProfile() {
        Task {
            do {
                let account = try await APIService.getMyAccount()
                await MainActor.run {
                    // Extract first name from full name
                    let fullName = account.name
                    let firstName = fullName.components(separatedBy: " ").first ?? fullName
                    userName = firstName
                    isLoadingUser = false
                }
            } catch {
                await MainActor.run {
                    userName = "there"
                    isLoadingUser = false
                    print("Failed to load user profile: \(error)")
                }
            }
        }
    }
    
    // Load initial news items
    private func loadInitialNews() {
        newsItems = generateNewsItems()
        displayedNewsCount = 3
    }
    
    // Load 3 more news items
    private func loadMoreNews() {
        withAnimation {
            displayedNewsCount = min(displayedNewsCount + 3, newsItems.count)
        }
    }
    
    // Collapse news back to 3 items
       private func collapseNews() {
           withAnimation {
               displayedNewsCount = 3
           }
       }
    
    // Generate sample news items (replace with actual API call later)
    private func generateNewsItems() -> [NewsItem] {
        return [
            NewsItem(
                imageName: "icu_guidelines",
                category: "Guidelines",
                categoryColor: Color.blue.opacity(0.2),
                timeAgo: "2 hours ago",
                title: "New GuideLines for ICU patient Care Released",
                description: "The American Nurses Associate has published updated guidelines for ...",
                readTime: "3 min read",
                views: "1.2K"
            ),
            NewsItem(
                imageName: "ai_technology",
                category: "Technology",
                categoryColor: Color.pink.opacity(0.3),
                timeAgo: "3 hours ago",
                title: "AI Technology Transforms Nursing Education",
                description: "The American Nurses Associate has published updated guidelines for ...",
                readTime: "5 min read",
                views: "2K"
            ),
            NewsItem(
                imageName: "nursing_conference",
                category: "Event",
                categoryColor: Color.green.opacity(0.3),
                timeAgo: "4 hours ago",
                title: "National Nursing Conference 2025 Announced",
                description: "Registration is now open for the largest nursing professional development...",
                readTime: "9 min read",
                views: "1.4K"
            ),
            NewsItem(
                imageName: "patient_safety",
                category: "Safety",
                categoryColor: Color.orange.opacity(0.2),
                timeAgo: "5 hours ago",
                title: "Patient Safety Protocols Updated for 2025",
                description: "New safety measures implemented across healthcare facilities nationwide...",
                readTime: "4 min read",
                views: "980"
            ),
            NewsItem(
                imageName: "mental_health",
                category: "Wellness",
                categoryColor: Color.purple.opacity(0.2),
                timeAgo: "6 hours ago",
                title: "Mental Health Support for Healthcare Workers",
                description: "New initiatives launched to support nurse mental health and wellbeing...",
                readTime: "6 min read",
                views: "1.5K"
            ),
            NewsItem(
                imageName: "research",
                category: "Research",
                categoryColor: Color.teal.opacity(0.2),
                timeAgo: "8 hours ago",
                title: "Breakthrough Research in Wound Care Published",
                description: "Latest studies show promising results in advanced wound healing techniques...",
                readTime: "7 min read",
                views: "856"
            ),
            NewsItem(
                imageName: "training",
                category: "Training",
                categoryColor: Color.indigo.opacity(0.2),
                timeAgo: "10 hours ago",
                title: "New CPR Training Standards Announced",
                description: "American Heart Association releases updated CPR certification requirements...",
                readTime: "5 min read",
                views: "2.3K"
            ),
            NewsItem(
                imageName: "policy",
                category: "Policy",
                categoryColor: Color.red.opacity(0.2),
                timeAgo: "12 hours ago",
                title: "Healthcare Policy Changes Take Effect",
                description: "Major policy updates affecting nursing practice begin implementation...",
                readTime: "8 min read",
                views: "1.8K"
            ),
            NewsItem(
                imageName: "innovation",
                category: "Innovation",
                categoryColor: Color.cyan.opacity(0.2),
                timeAgo: "1 day ago",
                title: "Smart Hospital Technology Revolutionizes Care",
                description: "IoT devices and AI integration improve patient outcomes and efficiency...",
                readTime: "6 min read",
                views: "1.1K"
            )
        ]
    }
}

// News Item Model
struct NewsItem: Identifiable {
    let id = UUID()
    let imageName: String
    let category: String
    let categoryColor: Color
    let timeAgo: String
    let title: String
    let description: String
    let readTime: String
    let views: String
}

// News Card Component
struct NewsCard: View {
    let imageName: String
    let category: String
    let categoryColor: Color
    let timeAgo: String
    let title: String
    let description: String
    let readTime: String
    let views: String
    
    var body: some View {
        Button {
            // Handle card tap
        } label: {
            HStack(alignment: .top, spacing: 10) {
                // Image
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 90, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Category and Time
                    HStack(spacing: 6) {
                        Text(category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor)
                            .cornerRadius(8)
                        
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Title
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Description
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    // Stats
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(readTime)
                                .font(.system(size: 9))
                        }
                        
                        HStack(spacing: 3) {
                            Image(systemName: "eye")
                                .font(.system(size: 9))
                            Text(views)
                                .font(.system(size: 9))
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}
