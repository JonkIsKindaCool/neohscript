function main() {
	var test = {
		name: "Aeae",
		age: 28,
		email: "aeae@example.com",
		phone: "+1-555-0199",
		address: {
			street: "123 Main Street",
			city: "Springfield",
			state: "IL",
			zipCode: "62701",
			country: "USA",
			coordinates: { lat: 39.7817, lng: -89.6501 }
		},
		profile: {
			bio: "Just a chill developer who loves Haxe.",
			avatar: "https://cdn.example.com/avatars/aeae.png",
			website: "https://aeae.dev",
			occupation: "Software Engineer",
			company: "Acme Corp",
			department: "Platform",
			yearsOfExperience: 6
		},
		preferences: {
			theme: "dark",
			language: "en-US",
			timezone: "America/Chicago",
			currency: "USD",
			notifications: {
				email: true,
				sms: false,
				push: true,
				marketing: false,
				newsletter: true
			}
		},
		social: {
			twitter: "@aeae",
			linkedin: "linkedin.com/in/aeae",
			github: "github.com/aeae",
			instagram: "@aeae.dev",
			facebook: ""
		},
		stats: {
			postsCount: 142,
			followersCount: 3820,
			followingCount: 310,
			likesReceived: 18540,
			commentsReceived: 4210,
			profileViews: 92100,
			reputation: 4.87
		},
		subscription: {
			plan: "pro",
			status: "active",
			startDate: "2024-01-15",
			endDate: "2025-01-15",
			autoRenew: true,
			price: 9.99,
			currency: "USD"
		},
		security: {
			twoFactorEnabled: true,
			lastLogin: "2026-04-29T08:23:00Z",
			lastPasswordChange: "2025-11-02T14:00:00Z",
			loginAttempts: 0,
			trustedDevices: 3,
			sessionTimeout: 3600
		},
		metadata: {
			createdAt: "2021-06-10T10:00:00Z",
			updatedAt: "2026-04-29T08:23:00Z",
			deletedAt: null,
			version: 7,
			isActive: true,
			isVerified: true,
			isAdmin: false,
			tags: ["haxe", "developer", "open-source", "gamedev"]
		}
	};

	return test;
}