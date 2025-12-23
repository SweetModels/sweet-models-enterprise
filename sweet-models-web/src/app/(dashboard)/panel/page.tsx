/**
 * ============================================================================
 * SWEET MODELS ENTERPRISE - DASHBOARD PANEL
 * Protected route - Main admin panel (requires authentication)
 * ============================================================================
 */

import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Dashboard',
  description: 'Main control panel for Sweet Models Enterprise',
};

export default function DashboardPanel() {
  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold mb-2">Dashboard</h1>
        <p className="text-gray-400">Welcome back! Here's your performance overview.</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="p-6 border border-gray-800 rounded-lg">
          <div className="text-gray-400 text-sm mb-2">Total Earnings</div>
          <div className="text-3xl font-bold text-pink-500">$12,450.50</div>
          <div className="text-green-400 text-sm mt-2">+12% this month</div>
        </div>
        <div className="p-6 border border-gray-800 rounded-lg">
          <div className="text-gray-400 text-sm mb-2">Active Contracts</div>
          <div className="text-3xl font-bold text-purple-500">8</div>
          <div className="text-gray-400 text-sm mt-2">All active</div>
        </div>
        <div className="p-6 border border-gray-800 rounded-lg">
          <div className="text-gray-400 text-sm mb-2">Total Views</div>
          <div className="text-3xl font-bold text-indigo-500">124.5K</div>
          <div className="text-green-400 text-sm mt-2">+8% this week</div>
        </div>
        <div className="p-6 border border-gray-800 rounded-lg">
          <div className="text-gray-400 text-sm mb-2">Followers</div>
          <div className="text-3xl font-bold text-cyan-500">8,320</div>
          <div className="text-green-400 text-sm mt-2">+245 this week</div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="p-6 border border-gray-800 rounded-lg">
        <h2 className="text-xl font-semibold mb-4">Recent Activity</h2>
        <div className="space-y-4">
          <div className="flex items-center justify-between py-3 border-b border-gray-800">
            <div>
              <p className="font-medium">Contract Signed</p>
              <p className="text-sm text-gray-400">Fashion Campaign Q1 2025</p>
            </div>
            <div className="text-right">
              <p className="font-medium text-green-400">+$2,500</p>
              <p className="text-sm text-gray-400">2 hours ago</p>
            </div>
          </div>
          <div className="flex items-center justify-between py-3 border-b border-gray-800">
            <div>
              <p className="font-medium">Payout Processed</p>
              <p className="text-sm text-gray-400">Monthly earnings</p>
            </div>
            <div className="text-right">
              <p className="font-medium text-blue-400">$1,850</p>
              <p className="text-sm text-gray-400">1 day ago</p>
            </div>
          </div>
          <div className="flex items-center justify-between py-3">
            <div>
              <p className="font-medium">Performance Report</p>
              <p className="text-sm text-gray-400">Monthly analytics updated</p>
            </div>
            <div className="text-right">
              <p className="font-medium text-purple-400">+12% growth</p>
              <p className="text-sm text-gray-400">3 days ago</p>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <button className="p-6 border border-gray-800 rounded-lg text-left hover:border-gray-700 transition">
          <h3 className="font-semibold text-lg mb-2">📄 View Contracts</h3>
          <p className="text-gray-400 text-sm">Browse and manage all your active contracts</p>
        </button>
        <button className="p-6 border border-gray-800 rounded-lg text-left hover:border-gray-700 transition">
          <h3 className="font-semibold text-lg mb-2">💰 Request Payout</h3>
          <p className="text-gray-400 text-sm">Withdraw your earnings to your preferred method</p>
        </button>
      </div>
    </div>
  );
}
