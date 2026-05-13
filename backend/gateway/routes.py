# URL prefix → downstream service base URL
ROUTE_MAP: dict[str, str] = {
    "/auth":          "http://localhost:8001",
    "/users":         "http://localhost:8002",
    "/therapists":    "http://localhost:8003",
    "/journal":       "http://localhost:8004",
    "/chat":          "http://localhost:8005",
    "/community":     "http://localhost:8006",
    "/notifications": "http://localhost:8007",
    "/wellness":      "http://localhost:8008",
    "/admin":         "http://localhost:8009",
}
